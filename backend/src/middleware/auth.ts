import { Hono } from 'hono'
import { getSupabaseFromContext } from '../utils/supabase'

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

const verifyAuth = async (authHeader: string, supabase: any) => {
  const token = authHeader.replace('Bearer ', '')
  const { data: { user }, error } = await supabase.auth.getUser(token)
  if (error) {
    return null
  }
  return user
}

export const authMiddleware = async (c: any, next: any) => {
  const supabase = getSupabaseFromContext(c)
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

  let { data: profile, error } = await supabase
    .from('profiles')
    .select('*')
    .eq('auth_user_id', user.id)
    .single()

  // Auto-create profile if it doesn't exist
  if (error || !profile) {
    try {
      // Generate invite slug for new family
      const inviteSlug = Buffer.from(crypto.randomUUID()).toString('hex').substring(0, 8)

      // Create family first
      const { data: family, error: familyError } = await supabase
        .from('families')
        .insert({
          name: 'My Family',
          invite_slug: inviteSlug,
        })
        .select()
        .single()

      if (familyError || !family) {
        console.error('[ProfileMiddleware] Failed to create family:', familyError)
        return c.json({ error: 'Failed to create family', details: familyError?.message }, 500)
      }

      // Create profile
      const { data: newProfile, error: profileError } = await supabase
        .from('profiles')
        .insert({
          auth_user_id: user.id,
          family_id: family.id,
          full_name: user.user_metadata?.full_name || user.user_metadata?.name || 'Anonymous User',
          role: 'organizer',
        })
        .select()
        .single()

      if (profileError || !newProfile) {
        console.error('[ProfileMiddleware] Failed to create profile:', profileError)
        return c.json({ error: 'Failed to create profile', details: profileError?.message }, 500)
      }

      profile = newProfile
      console.log('[ProfileMiddleware] Auto-created profile and family for user:', user.id)
    } catch (err) {
      console.error('[ProfileMiddleware] Exception during profile creation:', err)
      return c.json({ error: 'Failed to initialize user profile', details: err instanceof Error ? err.message : 'Unknown error' }, 500)
    }
  }

  c.set('profile' as const, profile)
  await next()
}

