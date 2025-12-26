import { Hono } from 'hono'
import { authMiddleware, profileMiddleware } from '../middleware/auth'

const app = new Hono()

app.get('/api/stories', authMiddleware, profileMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const profile = c.get('profile')

  const { data: stories, error } = await supabase
    .from('stories')
    .select(`
      *,
      prompt:prompts(text, category),
      profiles:responses(user_id, source, duration_seconds)
    `)
    .eq('family_id', profile.family_id)
    .order('created_at', { ascending: false })

  if (error) {
    return c.json({ error: error.message }, 500)
  }

  return c.json(stories)
})

app.get('/api/stories/:id', async (c) => {
  const supabase = c.get('supabase')
  const storyId = c.req.param('id')

  const { data: story, error } = await supabase
    .from('stories')
    .select(`
      *,
      prompt:prompts(text, category),
      responses(
        id,
        user_id,
        source,
        media_url,
        transcription_text,
        duration_seconds,
        created_at,
        profiles(full_name, role, avatar_url)
      )
    `)
    .eq('id', storyId)
    .single()

  if (error || !story) {
    return c.json({ error: 'Story not found' }, 404)
  }

  return c.json(story)
})

app.post('/api/stories', authMiddleware, profileMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const profile = c.get('profile')
  const body = await c.req.json()

  const { data: story, error } = await supabase
    .from('stories')
    .insert({
      prompt_id: body.prompt_id,
      family_id: profile.family_id,
      voice_count: 1,
      is_completed: false,
    })
    .select()
    .single()

  if (error) {
    return c.json({ error: error.message }, 500)
  }

  return c.json(story, 201)
})

app.patch('/api/stories/:id/complete', async (c) => {
  const supabase = c.get('supabase')
  const storyId = c.req.param('id')
  const body = await c.req.json()

  const { data, error } = await supabase
    .from('stories')
    .update({
      is_completed: true,
      title: body.title,
      summary_text: body.summary,
      cover_image_url: body.cover_image_url,
      voice_count: body.voice_count,
    })
    .eq('id', storyId)
    .select()
    .single()

  if (error) {
    return c.json({ error: error.message }, 500)
  }

  return c.json(data)
})

export default app

