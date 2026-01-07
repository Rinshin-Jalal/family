import { Hono } from 'hono'
import { authMiddleware } from '../middleware/auth'

const app = new Hono<{ Bindings: any; Variables: any }>()

/**
 * POST /api/analytics/track
 * Track an analytics event
 */
app.post('/api/analytics/track', async (c) => {
  const supabase = c.get('supabase')
  const body = await c.req.json()
  const { event_type, event_category, properties, session_id } = body
  
  const userId = c.get('userId')
  
  await supabase.rpc('track_event', {
    p_event_type: event_type,
    p_event_category: event_category || 'general',
    p_user_id: userId || null,
    p_session_id: session_id || crypto.randomUUID(),
    p_properties: properties || {},
    p_platform: 'ios',
  })
  
  return c.json({ success: true })
})

/**
 * GET /api/analytics/events
 * Get user's recent events (paginated)
 */
app.get('/api/analytics/events', authMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const userId = c.get('userId')
  const limit = parseInt(c.req.query('limit') || '50')
  const offset = parseInt(c.req.query('offset') || '0')
  
  const { data: profile } = await supabase
    .from('profiles')
    .select('id')
    .eq('auth_user_id', userId)
    .single()
  
  if (!profile) {
    return c.json({ error: 'Profile not found' }, 404)
  }
  
  const { data: events, error } = await supabase
    .from('analytics_events')
    .select('*')
    .eq('user_id', profile.id)
    .order('created_at', { ascending: false })
    .range(offset, offset + limit - 1)
  
  if (error) {
    return c.json({ error: 'Failed to fetch events' }, 500)
  }
  
  return c.json({ events: events || [], count: events?.length || 0 })
})

/**
 * GET /api/analytics/popular-stories
 * Get popular stories for user's family
 */
app.get('/api/analytics/popular-stories', authMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const userId = c.get('userId')
  const limit = parseInt(c.req.query('limit') || '10')
  
  const { data: profile } = await supabase
    .from('profiles')
    .select('id, family_id')
    .eq('auth_user_id', userId)
    .single()
  
  if (!profile) {
    return c.json({ error: 'Profile not found' }, 404)
  }
  
  const { data: stories, error } = await supabase
    .rpc('get_popular_stories', {
      p_family_id: profile.family_id,
      p_limit: limit,
    })
  
  if (error) {
    return c.json({ error: 'Failed to fetch popular stories' }, 500)
  }
  
  return c.json({ stories: stories || [] })
})

/**
 * GET /api/analytics/dashboard
 * Get dashboard metrics for user's family
 */
app.get('/api/analytics/dashboard', authMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const userId = c.get('userId')
  const days = parseInt(c.req.query('days') || '7')
  
  const { data: profile } = await supabase
    .from('profiles')
    .select('id, family_id')
    .eq('auth_user_id', userId)
    .single()
  
  if (!profile) {
    return c.json({ error: 'Profile not found' }, 404)
  }
  
  const startDate = new Date()
  startDate.setDate(startDate.getDate() - days)
  
  const { data: events } = await supabase
    .from('analytics_events')
    .select('event_type, created_at')
    .eq('user_id', profile.id)
    .gte('created_at', startDate.toISOString())
  
  const { data: metrics } = await supabase
    .from('daily_metrics')
    .select('*')
    .eq('family_id', profile.family_id)
    .gte('metric_date', startDate.toISOString().split('T')[0])
  
  const eventCounts: Record<string, number> = {}
  if (events) {
    for (const event of events) {
      eventCounts[event.event_type] = (eventCounts[event.event_type] || 0) + 1
    }
  }
  
  return c.json({
    period: days,
    eventCounts,
    metrics: metrics || [],
    totalEvents: events?.length || 0,
  })
})

/**
 * GET /api/analytics/feature-flags
 * Get enabled features for current user
 */
app.get('/api/analytics/feature-flags', authMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const userId = c.get('userId')
  
  const { data: profile } = await supabase
    .from('profiles')
    .select('id')
    .eq('auth_user_id', userId)
    .single()
  
  if (!profile) {
    return c.json({ error: 'Profile not found' }, 404)
  }
  
  const { data: flags } = await supabase
    .from('feature_flags')
    .select('feature_name, is_enabled, minimum_plan_tier, rollout_percentage')
    .eq('is_enabled', true)
  
  const enabledFeatures: Record<string, object> = {}
  if (flags) {
    for (const flag of flags) {
      const isEnabled = await supabase.rpc('is_feature_enabled', {
        p_feature_name: flag.feature_name,
        p_user_id: profile.id,
      })
      
      if (isEnabled) {
        enabledFeatures[flag.feature_name] = {
          minimumPlanTier: flag.minimum_plan_tier,
          rolloutPercentage: flag.rollout_percentage,
        }
      }
    }
  }
  
  return c.json({ features: enabledFeatures })
})

/**
 * POST /api/analytics/feature-check/:featureName
 * Check if a specific feature is enabled
 */
app.post('/api/analytics/feature-check/:featureName', authMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const featureName = c.req.param('featureName')
  const userId = c.get('userId')
  
  const { data: profile } = await supabase
    .from('profiles')
    .select('id')
    .eq('auth_user_id', userId)
    .single()
  
  if (!profile) {
    return c.json({ error: 'Profile not found' }, 404)
  }
  
  const isEnabled = await supabase.rpc('is_feature_enabled', {
    p_feature_name: featureName,
    p_user_id: profile.id,
  })
  
  return c.json({ featureName, isEnabled })
})

export default app
