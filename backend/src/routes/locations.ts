import { Hono } from 'hono'
import { getSupabaseFromContext } from '../utils/supabase'
import { logger, getUserId } from '../utils/logger'

type Bindings = {
  SUPABASE_URL: string
  SUPABASE_KEY: string
}

const app = new Hono<{ Bindings: Bindings }>()

// GET /locations - Get all location tags for user's family
app.get('/api/locations', async (c) => {
  const route = '/api/locations'
  const method = 'GET'

  logger.logRequest(route, method)

  const supabase = getSupabaseFromContext(c)
  const { data: { user }, error: authError } = await supabase.auth.getUser()

  if (authError || !user) {
    logger.logAuthError('getUser', authError, { route })
    return c.json({ error: 'Unauthorized' }, 401)
  }

  // Get user's family_id
  const { data: profile, error: profileError } = await supabase
    .from('profiles')
    .select('family_id')
    .eq('auth_user_id', user.id)
    .single()

  if (profileError || !profile) {
    logger.logDBError('SELECT', 'profiles', profileError, { route, userId: user.id })
    return c.json({ error: 'Profile not found' }, 404)
  }

  // Get stories with location tags
  const { data: locations, error } = await supabase
    .from('location_tags')
    .select(`
      *,
      stories (
        id,
        title,
        created_at
      )
    `)
    .in('story_id', (
      supabase
        .from('stories')
        .select('id')
        .eq('family_id', profile.family_id)
    ))

  if (error) {
    logger.logDBError('SELECT', 'location_tags', error, { route, userId: user.id, familyId: profile.family_id })
    return c.json({ error: error.message }, 500)
  }

  logger.info(`Locations fetched successfully`, { route, userId: user.id, count: locations?.length || 0 })
  return c.json(locations)
})

// GET /api/locations/:storyId - Get location tags for a specific story
app.get('/api/locations/:storyId', async (c) => {
  const supabase = getSupabaseFromContext(c)
  const storyId = c.req.param('storyId')
  const { data: { user }, error: authError } = await supabase.auth.getUser()

  if (authError || !user) {
    return c.json({ error: 'Unauthorized' }, 401)
  }

  const { data: locations, error } = await supabase
    .from('location_tags')
    .select('*')
    .eq('story_id', storyId)

  if (error) {
    return c.json({ error: error.message }, 500)
  }

  return c.json(locations)
})

// POST /locations - Create a new location tag
app.post('/api/locations', async (c) => {
  const route = '/api/locations'
  const method = 'POST'

  logger.logRequest(route, method)

  const supabase = getSupabaseFromContext(c)
  const body = await c.req.json<{
    story_id: string
    place_name: string
    place_type?: string
    latitude?: number
    longitude?: number
    address?: string
  }>()

  const { data: { user }, error: authError } = await supabase.auth.getUser()

  if (authError || !user) {
    logger.logAuthError('getUser', authError, { route })
    return c.json({ error: 'Unauthorized' }, 401)
  }

  const { data, error } = await supabase
    .from('location_tags')
    .insert({
      story_id: body.story_id,
      place_name: body.place_name,
      place_type: body.place_type || 'other',
      latitude: body.latitude,
      longitude: body.longitude,
      address: body.address,
      created_by: user.id
    })
    .select()
    .single()

  if (error) {
    logger.logDBError('INSERT', 'location_tags', error, { route, userId: user.id, storyId: body.story_id })
    return c.json({ error: error.message }, 500)
  }

  logger.info(`Location tag created`, { route, userId: user.id, locationId: data.id })
  return c.json(data, 201)
})

// DELETE /locations/:id - Delete a location tag
app.delete('/api/locations/:id', async (c) => {
  const supabase = getSupabaseFromContext(c)
  const id = c.req.param('id')
  const { data: { user }, error: authError } = await supabase.auth.getUser()

  if (authError || !user) {
    return c.json({ error: 'Unauthorized' }, 401)
  }

  const { error } = await supabase
    .from('location_tags')
    .delete()
    .eq('id', id)

  if (error) {
    return c.json({ error: error.message }, 500)
  }

  return c.json({ deleted: true })
})

export default app
