import { Hono } from 'hono'
import { authMiddleware, profileMiddleware } from '../middleware/auth'

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

  // Only add Bearer token if not using service role
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

  if (response.status === 204) {
    return null
  }

  const text = await response.text()
  if (!text) {
    return null
  }

  return JSON.parse(text)
}

app.post('/api/families', authMiddleware, profileMiddleware, async (c) => {
  const accessToken = c.get('accessToken')
  const profile = c.get('profile')
  const { name } = await c.req.json() as { name?: string }

  if (!name || name.trim().length === 0) {
    return c.json({ error: 'Family name is required' }, 400)
  }

  if (profile?.family_id) {
    return c.json({ error: 'User is already a member of a family' }, 400)
  }

  const inviteSlug = Math.random().toString(36).substring(2, 10)

  try {
    console.log('[Families] Creating family with name:', name)
    
    const family = await callSupabaseREST(
      '/families',
      c.env,
      accessToken,
      {
        method: 'POST',
        body: {
          name: name.trim(),
          invite_slug: inviteSlug,
        },
        returnRepresentation: true,
        useServiceRole: true,
      }
    )

    console.log('[Families] REST response:', family)

    if (!family || !Array.isArray(family) || family.length === 0) {
      console.log('[Families] Invalid response format:', typeof family, Array.isArray(family))
      return c.json({ error: 'Failed to create family - invalid response' }, 500)
    }

    const createdFamily = family[0]

    console.log('[Families] Updating profile family_id to:', createdFamily.id)
    
    await callSupabaseREST(
      `/profiles?id=eq.${profile.id}`,
      c.env,
      accessToken,
      {
        method: 'PATCH',
        body: { family_id: createdFamily.id },
        useServiceRole: true,
      }
    )

    console.log('[Families] Profile updated successfully')

    return c.json({
      success: true,
      family: {
        id: createdFamily.id,
        name: createdFamily.name,
        inviteSlug: createdFamily.invite_slug,
        inviteUrl: `https://storyrd.app/join/${createdFamily.invite_slug}`,
      },
    }, 201)
  } catch (error) {
    console.error('[Families] Creation error:', error instanceof Error ? error.message : error)
    console.error('[Families] Stack:', error instanceof Error ? error.stack : 'N/A')
    return c.json({ error: 'Failed to create family', details: error instanceof Error ? error.message : String(error) }, 500)
  }
})

app.get('/api/families', authMiddleware, profileMiddleware, async (c) => {
  const accessToken = c.get('accessToken')
  const profile = c.get('profile')

  if (!profile?.family_id) {
    return c.json({ error: 'User not in a family' }, 404)
  }

  const families = await callSupabaseREST(
    `/families?id=eq.${profile.family_id}`,
    c.env,
    accessToken,
    { useServiceRole: true }
  )

  if (!families || !Array.isArray(families) || families.length === 0) {
    return c.json({ error: 'Family not found' }, 404)
  }

  const family = families[0]
  return c.json(family)
})

app.get('/api/families/:id/members', authMiddleware, profileMiddleware, async (c) => {
  const accessToken = c.get('accessToken')
  const profile = c.get('profile')
  const familyId = c.req.param('id')

  if (profile?.family_id !== familyId) {
    return c.json({ error: 'Unauthorized' }, 403)
  }

  const members = await callSupabaseREST(
    `/profiles?family_id=eq.${familyId}&order=created_at.asc`,
    c.env,
    accessToken,
    { useServiceRole: true }
  )

  if (!members || !Array.isArray(members)) {
    return c.json({ error: 'Failed to fetch members' }, 500)
  }

  return c.json(members)
})

app.post('/api/families/:id/invite', authMiddleware, profileMiddleware, async (c) => {
  const accessToken = c.get('accessToken')
  const profile = c.get('profile')
  const familyId = c.req.param('id')

  if (profile?.family_id !== familyId) {
    return c.json({ error: 'Unauthorized' }, 403)
  }

  const currentUsers = await callSupabaseREST(
    `/profiles?id=eq.${profile.id}`,
    c.env,
    accessToken,
    { useServiceRole: true }
  )

  if (!currentUsers || !Array.isArray(currentUsers) || currentUsers.length === 0) {
    return c.json({ error: 'User not found' }, 404)
  }

  const currentUser = currentUsers[0]
  if (currentUser.role !== 'organizer') {
    return c.json({ error: 'Only organizers can generate invite links' }, 403)
  }

  const newSlug = Math.random().toString(36).substring(2, 10)

  const updatedFamilies = await callSupabaseREST(
    `/families?id=eq.${familyId}`,
    c.env,
    accessToken,
    {
      method: 'PATCH',
      body: { invite_slug: newSlug },
      returnRepresentation: true,
      useServiceRole: true,
    }
  )

  if (!updatedFamilies || !Array.isArray(updatedFamilies) || updatedFamilies.length === 0) {
    return c.json({ error: 'Failed to generate invite' }, 500)
  }

  const family = updatedFamilies[0]
  return c.json({
    familyId: family.id,
    familyName: family.name,
    inviteSlug: family.invite_slug,
    inviteUrl: `https://storyrd.app/join/${family.invite_slug}`,
  })
})

app.post('/api/families/join', authMiddleware, profileMiddleware, async (c) => {
  const accessToken = c.get('accessToken')
  const profile = c.get('profile')
  const { invite_code } = await c.req.json() as { invite_code?: string }

  if (!invite_code) {
    return c.json({ error: 'Invite code is required' }, 400)
  }

  if (profile?.family_id) {
    return c.json({ error: 'You are already a member of a family' }, 400)
  }

  const families = await callSupabaseREST(
    `/families?invite_slug=eq.${invite_code}`,
    c.env,
    accessToken,
    { useServiceRole: true }
  )

  if (!families || !Array.isArray(families) || families.length === 0) {
    return c.json({ error: 'Invalid or expired invite code' }, 404)
  }

  const family = families[0]

  const updatedProfiles = await callSupabaseREST(
    `/profiles?id=eq.${profile.id}`,
    c.env,
    accessToken,
    {
      method: 'PATCH',
      body: { family_id: family.id },
      returnRepresentation: true,
      useServiceRole: true,
    }
  )

  if (!updatedProfiles || !Array.isArray(updatedProfiles) || updatedProfiles.length === 0) {
    return c.json({ error: 'Failed to join family' }, 500)
  }

  const updatedProfile = updatedProfiles[0]

  return c.json({
    success: true,
    family: {
      id: family.id,
      name: family.name,
    },
    profile: updatedProfile,
  })
})

app.get('/api/families/lookup/:invite_code', authMiddleware, async (c) => {
  const accessToken = c.get('accessToken')
  const inviteCode = c.req.param('invite_code')

  const families = await callSupabaseREST(
    `/families?invite_slug=eq.${inviteCode}`,
    c.env,
    accessToken,
    { useServiceRole: true }
  )

  if (!families || !Array.isArray(families) || families.length === 0) {
    return c.json({ error: 'Invalid or expired invite code' }, 404)
  }

  const family = families[0]

  const memberCountResponse = await fetch(
    `${c.env.SUPABASE_URL}/rest/v1/profiles?family_id=eq.${family.id}&select=*&count=exact&head=true`,
    {
      headers: {
        'apikey': c.env.SUPABASE_SERVICE_ROLE_KEY || c.env.SUPABASE_KEY,
      },
    }
  )

  const countHeader = memberCountResponse.headers.get('content-range')
  const memberCount = countHeader ? parseInt(countHeader.split('/')[1], 10) : 0

  return c.json({
    id: family.id,
    name: family.name,
    memberCount,
  })
})

export default app
