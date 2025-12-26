import { Hono } from 'hono'
import { createClient } from '@supabase/supabase-js'

type Bindings = {
  SUPABASE_URL: string
  SUPABASE_KEY: string
  AUDIO_BUCKET: R2Bucket
  OPENAI_API_KEY: string
}

type Variables = {
  user: any
  supabase: any
  profile: any
}

const getSupabase = (c: any) => {
  return createClient(c.env.SUPABASE_URL, c.env.SUPABASE_KEY)
}

const verifyAuth = async (authHeader: string, supabase: any) => {
  const token = authHeader.replace('Bearer ', '')
  const { data: { user }, error } = await supabase.auth.getUser(token)
  if (error) {
    return null
  }
  return user
}

export const authMiddleware = async (c: any, next: any) => {
  const supabase = getSupabase(c)
  const authHeader = c.req.header('Authorization')

  if (!authHeader) {
    return c.json({ error: 'Unauthorized' }, 401)
  }

  const user = await verifyAuth(authHeader, supabase)
  if (!user) {
    return c.json({ error: 'Invalid token' }, 401)
  }

  c.set('user' as const, user)
  c.set('supabase' as const, supabase)
  await next()
}

export const profileMiddleware = async (c: any, next: any) => {
  const user = c.get('user')
  const supabase = c.get('supabase')

  const { data: profile, error } = await supabase
    .from('profiles')
    .select('*')
    .eq('auth_user_id', user.id)
    .single()

  if (error || !profile) {
    return c.json({ error: 'Profile not found' }, 404)
  }

  c.set('profile' as const, profile)
  await next()
}

