import { Hono } from 'hono'

const app = new Hono()

async function callSupabaseREST(
  url: string,
  env: { SUPABASE_URL: string; SUPABASE_KEY: string; SUPABASE_SERVICE_ROLE_KEY?: string },
  accessToken: string | null,
  options: {
    method?: string
    body?: unknown
    returnRepresentation?: boolean
    useServiceRole?: boolean
  } = {}
) {
  const headers: Record<string, string> = {
    'apikey': options.useServiceRole ? (env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_KEY) : env.SUPABASE_KEY,
    'Content-Type': 'application/json',
  }

  if (accessToken && !options.useServiceRole) {
    headers['Authorization'] = `Bearer ${accessToken}`
  }

  if (options.returnRepresentation) {
    headers['Prefer'] = 'return=representation'
  }

  const response = await fetch(`${env.SUPABASE_URL}/rest/v1${url}`, {
    method: options.method || 'GET',
    headers,
    body: options.body ? JSON.stringify(options.body) : undefined,
  })

  if (!response.ok) {
    const text = await response.text()
    throw new Error(`Supabase API error: ${response.status} ${text}`)
  }

  const text = await response.text()
  if (!text) {
    return null
  }

  try {
    return JSON.parse(text)
  } catch (e) {
    throw new Error(`Failed to parse Supabase response: ${text}`)
  }
}

app.post('/auth/signup-with-invite', async (c) => {
  const { email, password, invite_code } = await c.req.json() as {
    email?: string
    password?: string
    invite_code?: string
  }

  if (!email || !password) {
    return c.json({ error: 'Email and password are required' }, 400)
  }

  const SUPABASE_URL = c.env.SUPABASE_URL
  const SUPABASE_KEY = c.env.SUPABASE_KEY

  try {
    // First, verify invite code exists
    if (invite_code) {
      const families = await callSupabaseREST(
        `/families?invite_slug=eq.${invite_code}`,
        c.env,
        null,
        { useServiceRole: true }
      )

      if (!families || !Array.isArray(families) || families.length === 0) {
        return c.json({ error: 'Invalid or expired invite code' }, 400)
      }
    }

    // Proceed with normal signup
    console.log('Signup attempt for:', email)
    
    const signupResponse = await fetch(`${SUPABASE_URL}/auth/v1/signup`, {
      method: 'POST',
      headers: {
        'apikey': SUPABASE_KEY,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email,
        password,
      }),
    })

    const signupData = await signupResponse.json() as {
      user?: { id: string; email: string }
      access_token?: string
      refresh_token?: string
      expires_in?: number
      expires_at?: number
      token_type?: string
      error?: { message: string }
    }

    if (!signupResponse.ok) {
      return c.json({
        error: signupData.error?.message || 'Signup failed'
      }, signupResponse.status)
    }

    // If invite_code provided, move user to that family
    if (invite_code && signupData.access_token) {
      const accessToken = signupData.access_token
      
      // Get user's profile
      const profiles = await callSupabaseREST(
        `/profiles?auth_user_id=eq.${signupData.user?.id}`,
        c.env,
        null,
        { useServiceRole: true }
      )

      if (profiles && Array.isArray(profiles) && profiles.length > 0) {
        const profile = profiles[0]
        
        // Get target family
        const families = await callSupabaseREST(
          `/families?invite_slug=eq.${invite_code}`,
          c.env,
          null,
          { useServiceRole: true }
        )

        if (families && Array.isArray(families) && families.length > 0) {
          const targetFamily = families[0]
          
          // Update profile to join target family
          await callSupabaseREST(
            `/profiles?id=eq.${profile.id}`,
            c.env,
            accessToken,
            {
              method: 'PATCH',
              body: { family_id: targetFamily.id },
              useServiceRole: true,
            }
          )
        }
      }
    }

    return c.json({
      user: signupData.user,
      session: {
        access_token: signupData.access_token,
        refresh_token: signupData.refresh_token,
        expires_in: signupData.expires_in,
        expires_at: signupData.expires_at,
        token_type: signupData.token_type,
        user: signupData.user,
      },
    }, 201)
  } catch (error) {
    console.error('Signup with invite error:', error instanceof Error ? error.message : error)
    return c.json({ error: 'Signup failed', details: error instanceof Error ? error.message : String(error) }, 500)
  }
})

app.post('/auth/signup', async (c) => {
  const { email, password, invite_slug } = await c.req.json() as {
    email?: string
    password?: string
    invite_slug?: string
  }

  if (!email || !password) {
    return c.json({ error: 'Email and password are required' }, 400)
  }

  const SUPABASE_URL = c.env.SUPABASE_URL
  const SUPABASE_KEY = c.env.SUPABASE_KEY

  try {
    console.log('Signup attempt for:', email)
    console.log('Supabase URL:', SUPABASE_URL)
    
    const body: Record<string, any> = {
      email,
      password,
    }

    // If invite_slug provided, add to user metadata so trigger can join existing family
    if (invite_slug) {
      body.data = { invite_slug }
    }

    const signupResponse = await fetch(`${SUPABASE_URL}/auth/v1/signup`, {
      method: 'POST',
      headers: {
        'apikey': SUPABASE_KEY,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    })

    const signupData = await signupResponse.json() as {
      user?: { id: string; email: string }
      access_token?: string
      refresh_token?: string
      expires_in?: number
      expires_at?: number
      token_type?: string
      error?: { message: string }
    }

    console.log('Signup response status:', signupResponse.status)
    console.log('Signup response data:', JSON.stringify(signupData))

    if (!signupResponse.ok) {
      return c.json({
        error: signupData.error?.message || 'Signup failed'
      }, signupResponse.status)
    }

    return c.json({
      user: signupData.user,
      session: {
        access_token: signupData.access_token,
        refresh_token: signupData.refresh_token,
        expires_in: signupData.expires_in,
        expires_at: signupData.expires_at,
        token_type: signupData.token_type,
        user: signupData.user,
      },
    }, 201)
  } catch (error) {
    console.error('Signup error:', error instanceof Error ? error.message : error)
    console.error('Stack:', error instanceof Error ? error.stack : 'N/A')
    return c.json({ error: 'Signup failed', details: error instanceof Error ? error.message : String(error) }, 500)
  }
})

app.post('/auth/signin', async (c) => {
  const { email, password } = await c.req.json() as {
    email?: string
    password?: string
  }

  if (!email || !password) {
    return c.json({ error: 'Email and password are required' }, 400)
  }

  const SUPABASE_URL = c.env.SUPABASE_URL
  const SUPABASE_KEY = c.env.SUPABASE_KEY

  try {
    const response = await fetch(`${SUPABASE_URL}/auth/v1/token?grant_type=password`, {
      method: 'POST',
      headers: {
        'apikey': SUPABASE_KEY,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email,
        password,
      }),
    })

    const data = await response.json() as {
      access_token?: string
      refresh_token?: string
      expires_in?: number
      expires_at?: number
      token_type?: string
      user?: { id: string; email: string }
      error?: string
    }

    if (!response.ok) {
      return c.json({
        error: data.error || 'Sign in failed'
      }, response.status)
    }

    return c.json({
      session: {
        access_token: data.access_token,
        refresh_token: data.refresh_token,
        expires_in: data.expires_in,
        expires_at: data.expires_at,
        token_type: data.token_type,
        user: data.user,
      },
    })
  } catch (error) {
    console.error('Sign in error:', error)
    return c.json({ error: 'Sign in failed' }, 500)
  }
})

app.post('/auth/refresh', async (c) => {
  const { refresh_token } = await c.req.json() as {
    refresh_token?: string
  }

  if (!refresh_token) {
    return c.json({ error: 'Refresh token is required' }, 400)
  }

  const SUPABASE_URL = c.env.SUPABASE_URL
  const SUPABASE_KEY = c.env.SUPABASE_KEY

  try {
    const response = await fetch(`${SUPABASE_URL}/auth/v1/token?grant_type=refresh_token`, {
      method: 'POST',
      headers: {
        'apikey': SUPABASE_KEY,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        refresh_token,
      }),
    })

    const data = await response.json() as {
      access_token?: string
      refresh_token?: string
      expires_in?: number
      expires_at?: number
      token_type?: string
      error?: string
    }

    if (!response.ok) {
      return c.json({
        error: data.error || 'Token refresh failed'
      }, response.status)
    }

    return c.json({
      session: {
        access_token: data.access_token,
        refresh_token: data.refresh_token,
        expires_in: data.expires_in,
        expires_at: data.expires_at,
        token_type: data.token_type,
      },
    })
  } catch (error) {
    console.error('Token refresh error:', error)
    return c.json({ error: 'Token refresh failed' }, 500)
  }
})

export default app
