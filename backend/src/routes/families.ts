import { Hono } from 'hono'
import { authMiddleware, profileMiddleware } from '../middleware/auth'

const app = new Hono()

/**
 * GET /api/families
 * Get current user's family info with invite slug
 */
app.get('/api/families', authMiddleware, profileMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const profile = c.get('profile')

  const { data: family, error } = await supabase
    .from('families')
    .select('id, name, invite_slug, plan_tier, created_at')
    .eq('id', profile.family_id)
    .single()

  if (error || !family) {
    return c.json({ error: 'Family not found' }, 404)
  }

  return c.json(family)
})

/**
 * GET /api/families/:id/members
 * Get all members of a family
 */
app.get('/api/families/:id/members', authMiddleware, profileMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const profile = c.get('profile')
  const familyId = c.req.param('id')

  // Verify user belongs to this family
  if (profile.family_id !== familyId) {
    return c.json({ error: 'Unauthorized' }, 403)
  }

  const { data: members, error } = await supabase
    .from('profiles')
    .select('id, full_name, avatar_url, role, phone_number, created_at')
    .eq('family_id', familyId)
    .order('created_at', { ascending: true })

  if (error) {
    return c.json({ error: error.message }, 500)
  }

  return c.json(members)
})

/**
 * POST /api/families/:id/invite
 * Generate/regenerate invite slug for a family
 * (Currently invites are auto-generated, but this endpoint can be used to refresh)
 */
app.post('/api/families/:id/invite', authMiddleware, profileMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const profile = c.get('profile')
  const familyId = c.req.param('id')

  // Verify user is organizer of this family
  const { data: currentUser } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', profile.id)
    .single()

  if (!currentUser || currentUser.role !== 'organizer') {
    return c.json({ error: 'Only organizers can generate invite links' }, 403)
  }

  // Verify family belongs to user
  if (profile.family_id !== familyId) {
    return c.json({ error: 'Unauthorized' }, 403)
  }

  // Generate new invite slug
  const newSlug = Math.random().toString(36).substring(2, 10)

  const { data: family, error } = await supabase
    .from('families')
    .update({ invite_slug: newSlug })
    .eq('id', familyId)
    .select('id, name, invite_slug')
    .single()

  if (error || !family) {
    return c.json({ error: error?.message || 'Failed to generate invite' }, 500)
  }

  return c.json({
    familyId: family.id,
    familyName: family.name,
    inviteSlug: family.invite_slug,
    inviteUrl: `https://storyrd.app/join/${family.invite_slug}`,
  })
})

export default app
