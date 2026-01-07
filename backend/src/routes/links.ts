import { Hono } from 'hono'
import { authMiddleware } from '../middleware/auth'

const app = new Hono<{ Bindings: any; Variables: any }>()

/**
 * GET /api/links/invite/:code
 * Resolve invite code to family info
 */
app.get('/api/links/invite/:code', async (c) => {
  const supabase = c.get('supabase')
  const inviteCode = c.req.param('code')

  const { data: family, error } = await supabase
    .from('families')
    .select('id, name, invite_slug')
    .eq('invite_slug', inviteCode)
    .single()

  if (error || !family) {
    return c.json({ error: 'Invite not found' }, 404)
  }

  return c.json({
    type: 'family_invite',
    familyId: family.id,
    familyName: family.name,
    inviteCode: family.invite_slug,
  })
})

/**
 * GET /api/links/story/:storyId
 * Get story info for sharing
 */
app.get('/api/links/story/:storyId', async (c) => {
  const supabase = c.get('supabase')
  const storyId = c.req.param('storyId')

  const { data: story, error } = await supabase
    .from('stories')
    .select('id, title, family_id')
    .eq('id', storyId)
    .single()

  if (error || !story) {
    return c.json({ error: 'Story not found' }, 404)
  }

  return c.json({
    type: 'story_share',
    storyId: story.id,
    title: story.title,
    url: `${c.env.APP_URL || 'https://storyrd.app'}/story/${storyId}`,
  })
})

/**
 * GET /api/links/quote/:quoteId
 * Get quote card info for sharing
 */
app.get('/api/links/quote/:quoteId', async (c) => {
  const supabase = c.get('supabase')
  const quoteId = c.req.param('quoteId')

  const { data: quote, error } = await supabase
    .from('quote_cards')
    .select('id, quote_text, author_name, image_url')
    .eq('id', quoteId)
    .single()

  if (error || !quote) {
    return c.json({ error: 'Quote not found' }, 404)
  }

  return c.json({
    type: 'quote_share',
    quoteId: quote.id,
    quote: quote.quote_text,
    author: quote.author_name,
    imageUrl: quote.image_url,
    url: `${c.env.APP_URL || 'https://storyrd.app'}/quote/${quoteId}`,
  })
})

/**
 * GET /api/links/request/:requestId
 * Get wisdom request info
 */
app.get('/api/links/request/:requestId', async (c) => {
  const supabase = c.get('supabase')
  const requestId = c.req.param('requestId')

  const { data: request, error } = await supabase
    .from('wisdom_requests')
    .select('id, question, requester_id')
    .eq('id', requestId)
    .single()

  if (error || !request) {
    return c.json({ error: 'Request not found' }, 404)
  }

  return c.json({
    type: 'wisdom_request',
    requestId: request.id,
    question: request.question,
    url: `${c.env.APP_URL || 'https://storyrd.app'}/request/${requestId}`,
  })
})

export default app
