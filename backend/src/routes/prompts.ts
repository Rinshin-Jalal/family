import { Hono } from 'hono'
import { authMiddleware, profileMiddleware } from '../middleware/auth'

const app = new Hono()

app.get('/api/prompts', authMiddleware, profileMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const profile = c.get('profile')

  const { data: prompts, error } = await supabase
    .from('prompts')
    .select('*')
    .eq('family_id', profile.family_id)
    .order('created_at', { ascending: false })

  if (error) {
    return c.json({ error: error.message }, 500)
  }

  return c.json(prompts)
})

app.post('/api/prompts', authMiddleware, profileMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const profile = c.get('profile')
  const body = await c.req.json()

  const { data: prompt, error } = await supabase
    .from('prompts')
    .insert({
      family_id: profile.family_id,
      text: body.text,
      category: body.category,
      is_custom: true,
    })
    .select()
    .single()

  if (error) {
    return c.json({ error: error.message }, 500)
  }

  return c.json(prompt, 201)
})

export default app

