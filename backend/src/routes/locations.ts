import { Hono } from 'hono'
import { getSupabase } from '../utils/supabase'
import { errorResponse, successResponse } from '../utils/errors'

type Bindings = {
  SUPABASE_URL: string
  SUPABASE_KEY: string
}

const app = new Hono<{ Bindings: Bindings }>()

// GET /locations - Get all location tags for user's family
app.get('/', async (c) => {
  const supabase = getSupabase(c)
  const { data: { user }, error: authError } = await supabase.auth.getUser()

  if (authError || !user) {
    return c.json(errorResponse('Unauthorized'), 401)
  }

  // Get user's family_id
  const { data: profile, error: profileError } = await supabase
    .from('profiles')
    .select('family_id')
    .eq('auth_user_id', user.id)
    .single()

  if (profileError || !profile) {
    return c.json(errorResponse('Profile not found'), 404)
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
    return c.json(errorResponse(error.message), 500)
  }

  return c.json(successResponse(locations))
})

// GET /locations/:storyId - Get location tags for a specific story
app.get('/:storyId', async (c) => {
  const supabase = getSupabase(c)
  const storyId = c.req.param('storyId')
  const { data: { user }, error: authError } = await supabase.auth.getUser()

  if (authError || !user) {
    return c.json(errorResponse('Unauthorized'), 401)
  }

  const { data: locations, error } = await supabase
    .from('location_tags')
    .select('*')
    .eq('story_id', storyId)

  if (error) {
    return c.json(errorResponse(error.message), 500)
  }

  return c.json(successResponse(locations))
})

// POST /locations - Create a new location tag
app.post('/', async (c) => {
  const supabase = getSupabase(c)
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
    return c.json(errorResponse('Unauthorized'), 401)
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
    return c.json(errorResponse(error.message), 500)
  }

  return c.json(successResponse(data), 201)
})

// DELETE /locations/:id - Delete a location tag
app.delete('/:id', async (c) => {
  const supabase = getSupabase(c)
  const id = c.req.param('id')
  const { data: { user }, error: authError } = await supabase.auth.getUser()

  if (authError || !user) {
    return c.json(errorResponse('Unauthorized'), 401)
  }

  const { error } = await supabase
    .from('location_tags')
    .delete()
    .eq('id', id)

  if (error) {
    return c.json(errorResponse(error.message), 500)
  }

  return c.json(successResponse({ deleted: true }))
})

export default app
