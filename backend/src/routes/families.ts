import { Hono } from 'hono'
import { authMiddleware, profileMiddleware } from '../middleware/auth'

const app = new Hono()

/**
 * POST /api/families
 * Create a new family for the current user
 */
app.post('/api/families', authMiddleware, profileMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const profile = c.get('profile')
  const { name } = await c.req.json()

  if (!name || name.trim().length === 0) {
    return c.json({ error: 'Family name is required' }, 400)
  }

  if (profile.family_id) {
    return c.json({ error: 'User is already a member of a family' }, 400)
  }

  const inviteSlug = Math.random().toString(36).substring(2, 10)

  const { data: family, error: createError } = await supabase
    .from('families')
    .insert({
      name: name.trim(),
      invite_slug: inviteSlug,
    })
    .select('id, name, invite_slug')
    .single()

  if (createError || !family) {
    return c.json({ error: 'Failed to create family' }, 500)
  }

  const { error: updateError } = await supabase
    .from('profiles')
    .update({ family_id: family.id })
    .eq('id', profile.id)

  if (updateError) {
    return c.json({ error: 'Failed to assign user to family' }, 500)
  }

  return c.json({
    success: true,
    family: {
      id: family.id,
      name: family.name,
      inviteSlug: family.invite_slug,
      inviteUrl: `https://storyrd.app/join/${family.invite_slug}`,
    },
  }, 201)
})

/**
 * GET /api/families
 * Get current user's family info with invite slug
 */
app.get('/api/families', authMiddleware, profileMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const profile = c.get('profile')
  const { name } = await c.req.json()

  if (!name || name.trim().length === 0) {
    return c.json({ error: 'Family name is required' }, 400)
  }

  if (profile.family_id) {
    return c.json({ error: 'User is already a member of a family' }, 400)
  }

  const inviteSlug = Math.random().toString(36).substring(2, 10)

  const { data: family, error } = await supabase
    .from('families')
    .select('id, name, invite_slug, plan_tier, created_at')
    .eq('id', profile.family_id)
    .single()

  if (error || !family) {
    return c.json({ error: 'Family not found' }, 404)
  }

  const family = families[0]
  return c.json(family)
})

app.get('/api/families/:id/members', authMiddleware, profileMiddleware, async (c) => {
  const accessToken = c.get('accessToken')
  const profile = c.get('profile')
  const familyId = c.req.param('id')

  if (profile.family_id !== familyId) {
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

  const { data: currentUser } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', profile.id)
    .single()

  if (!currentUser || currentUser.role !== 'organizer') {
    return c.json({ error: 'Only organizers can generate invite links' }, 403)
  }

  if (profile.family_id !== familyId) {
    return c.json({ error: 'Unauthorized' }, 403)
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

/**
 * POST /api/families/join
 * Join a family using an invite code
 */
app.post('/api/families/join', authMiddleware, profileMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const profile = c.get('profile')
  const { invite_code } = await c.req.json()

  if (!invite_code) {
    return c.json({ error: 'Invite code is required' }, 400)
  }

  if (profile.family_id) {
    return c.json({ error: 'You are already a member of a family' }, 400)
  }

  const { data: family, error: familyError } = await supabase
    .from('families')
    .select('id, name, invite_slug')
    .eq('invite_slug', invite_code)
    .single()

  if (familyError || !family) {
    return c.json({ error: 'Invalid or expired invite code' }, 404)
  }

  const { data: updatedProfile, error: updateError } = await supabase
    .from('profiles')
    .update({ family_id: family.id })
    .eq('id', profile.id)
    .select('id, full_name, avatar_url, role, family_id')
    .single()

  if (updateError) {
    return c.json({ error: 'Failed to join family' }, 500)
  }

  return c.json({
    success: true,
    family: {
      id: family.id,
      name: family.name,
    },
    profile: updatedProfile,
  })
})

/**
 * GET /api/families/lookup/:invite_code
 * Look up a family by invite code (before joining)
 */
app.get('/api/families/lookup/:invite_code', authMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const inviteCode = c.req.param('invite_code')

  const { data: family, error } = await supabase
    .from('families')
    .select('id, name')
    .eq('invite_slug', inviteCode)
    .single()

  if (error || !family) {
    return c.json({ error: 'Invalid or expired invite code' }, 404)
  }

  const { count } = await supabase
    .from('profiles')
    .select('*', { count: 'exact', head: true })
    .eq('family_id', family.id)

  return c.json({
    id: family.id,
    name: family.name,
    memberCount: count || 0,
  })
})

export default app
