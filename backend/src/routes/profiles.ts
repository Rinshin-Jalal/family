import { Hono } from 'hono'
import { authMiddleware, profileMiddleware } from '../middleware/auth'

const app = new Hono()

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

export default app

