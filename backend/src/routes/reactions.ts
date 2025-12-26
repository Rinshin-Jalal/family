import { Hono } from 'hono'
import { authMiddleware, profileMiddleware } from '../middleware/auth'

const app = new Hono()

app.post('/api/reactions', authMiddleware, profileMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const profile = c.get('profile')
  const body = await c.req.json()

  const { data: reaction, error } = await supabase
    .from('reactions')
    .insert({
      user_id: profile.id,
      target_id: body.target_id,
      target_type: body.target_type,
      emoji: body.emoji,
    })
    .select()
    .single()

  if (error) {
    return c.json({ error: error.message }, 500)
  }

  return c.json(reaction, 201)
})

export default app

