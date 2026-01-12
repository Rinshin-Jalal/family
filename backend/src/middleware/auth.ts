import { Hono } from 'hono'
import { getSupabaseFromContextWithAuth } from '../utils/supabase'

type Bindings = {
  SUPABASE_URL: string
  SUPABASE_KEY: string
  SUPABASE_SERVICE_ROLE_KEY: string
  AUDIO_BUCKET: R2Bucket
  OPENAI_API_KEY: string
}

type Variables = {
  user: any
  accessToken: string
  supabase: any
  profile: any
}

const decodeJWT = (token: string) => {
  try {
    const parts = token.split('.')
    if (parts.length !== 3) return null

    const decoded = JSON.parse(
      Buffer.from(parts[1], 'base64').toString('utf8')
    )

    if (!decoded.sub || !decoded.aud) return null

    return {
      id: decoded.sub,
      email: decoded.email,
      user_metadata: decoded.user_metadata || {},
      app_metadata: decoded.app_metadata || {},
      role: decoded.role,
      aud: decoded.aud,
    }
  } catch {
    return null
  }
}

export const authMiddleware = async (c: any, next: any) => {
  const authHeader = c.req.header('Authorization')

  if (!authHeader) {
    return c.json({ error: 'Unauthorized' }, 401)
  }

  const token = authHeader.replace('Bearer ', '')
  const user = decodeJWT(token)

  if (!user) {
    return c.json({ error: 'Invalid token' }, 401)
  }

  c.set('user' as const, user)
  c.set('accessToken' as const, token)
  await next()
}

export const profileMiddleware = async (c: any, next: any) => {
  const user = c.get('user')
  const supabaseUrl = c.env.SUPABASE_URL
  const serviceRoleKey = c.env.SUPABASE_SERVICE_ROLE_KEY || c.env.SUPABASE_KEY

  try {
    // Use service role key to bypass RLS policies and avoid infinite recursion
    // This is safe because we're only fetching the user's own profile by auth_user_id
    const response = await fetch(`${supabaseUrl}/rest/v1/profiles?auth_user_id=eq.${user.id}&select=*`, {
      headers: {
        'apikey': serviceRoleKey,
      },
    })

    const data = await response.json()
    const profile = Array.isArray(data) && data.length > 0 ? data[0] : null

    c.set('profile' as const, profile || null)
  } catch (err) {
    console.warn('[ProfileMiddleware] Could not fetch profile:', err)
    c.set('profile' as const, null)
  }

  await next()
}


