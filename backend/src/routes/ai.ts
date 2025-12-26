import { Hono } from 'hono'
import { authMiddleware } from '../middleware/auth'

const app = new Hono()

app.post('/api/ai/complete-story', authMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const body = await c.req.json()

  const title = `Generated Story: ${body.responses.length} voices`
  const summary = 'A heartwarming family memory shared together.'
  const coverImage = 'https://placeholder.com/story-cover.jpg'

  const { data: updated, error } = await supabase
    .from('stories')
    .update({
      title,
      summary_text: summary,
      cover_image_url: coverImage,
      is_completed: true,
    })
    .eq('id', body.story_id)
    .select()
    .single()

  if (error) {
    return c.json({ error: error.message }, 500)
  }

  return c.json(updated)
})

export default app

