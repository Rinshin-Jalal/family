import { Hono } from 'hono'
import { authMiddleware, profileMiddleware } from '../middleware/auth'

const app = new Hono()

/**
 * PATCH /api/settings/profile
 * Update current user's profile (name, avatar)
 */
app.patch('/api/settings/profile', authMiddleware, profileMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const profile = c.get('profile')
  const body = await c.req.json()

  const updates: Record<string, unknown> = {}
  if (body.name !== undefined) updates.full_name = body.name
  if (body.avatar_emoji !== undefined) updates.avatar_url = body.avatar_emoji
  // Note: theme preference would be stored separately if needed

  if (Object.keys(updates).length === 0) {
    return c.json({ error: 'No updates provided' }, 400)
  }

  const { data: updatedProfile, error } = await supabase
    .from('profiles')
    .update(updates)
    .eq('id', profile.id)
    .select('id, full_name, avatar_url, role, family_id')
    .single()

  if (error) {
    return c.json({ error: error.message }, 500)
  }

  return c.json(updatedProfile)
})

app.get('/api/profiles', authMiddleware, profileMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const profile = c.get('profile')

  const { data: profiles, error } = await supabase
    .from('profiles')
    .select('*')
    .eq('family_id', profile.family_id)

  if (error) {
    return c.json({ error: error.message }, 500)
  }

  return c.json(profiles)
})

app.post('/api/profiles/elder', authMiddleware, profileMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const profile = c.get('profile')
  const body = await c.req.json()

  const { data: elderProfile, error } = await supabase
    .from('profiles')
    .insert({
      family_id: profile.family_id,
      full_name: body.name,
      phone_number: body.phone_number,
      role: 'elder',
    })
    .select()
    .single()

  if (error) {
    return c.json({ error: error.message }, 500)
  }

  return c.json(elderProfile, 201)
})

/**
 * POST /api/profiles/member
 * Add a new family member directly (organizer only)
 * Creates a profile without auth_user_id - member can claim later via invite
 */
app.post('/api/profiles/member', authMiddleware, profileMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const profile = c.get('profile')
  const body = await c.req.json()

  // Verify user is an organizer
  if (profile.role !== 'organizer') {
    return c.json({ error: 'Only organizers can add family members' }, 403)
  }

  const { name, avatar_url, role = 'member' } = body

  if (!name || name.trim() === '') {
    return c.json({ error: 'Name is required' }, 400)
  }

  // Validate role
  const validRoles = ['member', 'child', 'elder', 'parent']
  if (!validRoles.includes(role)) {
    return c.json({ error: 'Invalid role' }, 400)
  }

  const { data: newMember, error } = await supabase
    .from('profiles')
    .insert({
      family_id: profile.family_id,
      full_name: name.trim(),
      avatar_url: avatar_url || null,
      role: role,
      auth_user_id: null, // No auth user - placeholder profile
    })
    .select('id, full_name, avatar_url, role, family_id, created_at')
    .single()

  if (error) {
    return c.json({ error: error.message }, 500)
  }

  return c.json(newMember, 201)
})

/**
 * PUT /api/profiles/:id
 * Update a profile (name, avatar, role)
 */
app.put('/api/profiles/:id', authMiddleware, profileMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const profile = c.get('profile')
  const targetId = c.req.param('id')
  const body = await c.req.json()

  // Check if updating own profile or if organizer
  const isSelf = targetId === profile.id
  const isOrganizer = profile.role === 'organizer'

  if (!isSelf && !isOrganizer) {
    return c.json({ error: 'Unauthorized' }, 403)
  }

  // Verify target profile is in same family
  const { data: targetProfile } = await supabase
    .from('profiles')
    .select('family_id')
    .eq('id', targetId)
    .single()

  if (!targetProfile || targetProfile.family_id !== profile.family_id) {
    return c.json({ error: 'Profile not found' }, 404)
  }

  const updates: Record<string, unknown> = {}
  if (body.name !== undefined) updates.full_name = body.name
  if (body.avatar_url !== undefined) updates.avatar_url = body.avatar_url
  if (body.role !== undefined && isOrganizer) updates.role = body.role

  if (Object.keys(updates).length === 0) {
    return c.json({ error: 'No updates provided' }, 400)
  }

  const { data: updatedProfile, error } = await supabase
    .from('profiles')
    .update(updates)
    .eq('id', targetId)
    .select('id, full_name, avatar_url, role, family_id')
    .single()

  if (error) {
    return c.json({ error: error.message }, 500)
  }

  return c.json(updatedProfile)
})

/**
 * DELETE /api/profiles/:id
 * Remove a family member (organizer only, cannot remove self)
 */
app.delete('/api/profiles/:id', authMiddleware, profileMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const profile = c.get('profile')
  const targetId = c.req.param('id')

  // Only organizers can remove members
  if (profile.role !== 'organizer') {
    return c.json({ error: 'Only organizers can remove family members' }, 403)
  }

  // Cannot remove self
  if (targetId === profile.id) {
    return c.json({ error: 'Cannot remove yourself from the family' }, 400)
  }

  // Verify target profile is in same family
  const { data: targetProfile } = await supabase
    .from('profiles')
    .select('family_id, role')
    .eq('id', targetId)
    .single()

  if (!targetProfile || targetProfile.family_id !== profile.family_id) {
    return c.json({ error: 'Profile not found' }, 404)
  }

  // Cannot remove another organizer
  if (targetProfile.role === 'organizer') {
    return c.json({ error: 'Cannot remove another organizer' }, 403)
  }

  const { error } = await supabase
    .from('profiles')
    .delete()
    .eq('id', targetId)

  if (error) {
    return c.json({ error: error.message }, 500)
  }

  return c.json({ success: true })
})

export default app

