import { Hono } from 'hono'
import { authMiddleware } from '../middleware/auth'

const app = new Hono<{ Bindings: any; Variables: any }>()

/**
 * POST /api/quotes/generate
 * Generate a quote card from a story response
 * Body: { story_id, response_id, theme?, background_color?, text_color? }
 */
app.post('/api/quotes/generate', authMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const body = await c.req.json()
  const { story_id, response_id, theme, background_color, text_color } = body
  const userId = c.get('userId')

  if (!story_id || !response_id) {
    return c.json({ error: 'story_id and response_id required' }, 400)
  }

  // Get the response with speaker info
  const { data: response, error } = await supabase
    .from('responses')
    .select(`
      id,
      transcription_text,
      profiles!inner(id, full_name, role, family_id)
    `)
    .eq('id', response_id)
    .eq('profiles.family_id', 
      supabase.from('profiles').select('family_id').eq('auth_user_id', userId).single()
    )
    .single()

  if (error || !response) {
    return c.json({ error: 'Response not found' }, 404)
  }

  // Extract quote from transcription (first meaningful sentence)
  const transcription = response.transcription_text
  const quote = extractQuote(transcription)
  const authorName = response.profiles.full_name || 'Family Member'
  const authorRole = response.profiles.role || 'family'

  // Create quote card record
  const { data: quoteCard, error: createError } = await supabase
    .from('quote_cards')
    .insert({
      quote_text: quote,
      author_name: authorName,
      author_role: authorRole,
      story_id: story_id,
      theme: theme || 'classic',
      background_color: background_color || '#FFFFFF',
      text_color: text_color || '#000000',
      created_by: supabase.from('profiles').select('id').eq('auth_user_id', userId).single().then(({ data }) => data?.id),
      family_id: response.profiles.family_id,
    })
    .select()
    .single()

  if (createError) {
    return c.json({ error: 'Failed to create quote card' }, 500)
  }

  return c.json({
    id: quoteCard.id,
    quote: quote,
    author: authorName,
    role: authorRole,
    theme: quoteCard.theme,
  }, 201)
})

/**
 * GET /api/quotes/popular
 * Get popular quote cards for the user's family
 */
app.get('/api/quotes/popular', authMiddleware, async (c) => {
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

  const { data: quoteCards, error } = await supabase
    .rpc('get_popular_quote_cards', {
      p_family_id: profile.family_id,
      p_limit: limit,
    })

  if (error) {
    return c.json({ error: 'Failed to fetch quote cards' }, 500)
  }

  return c.json({ quotes: quoteCards || [], count: quoteCards?.length || 0 })
})

/**
 * GET /api/quotes/:id
 * Get a specific quote card
 */
app.get('/api/quotes/:id', authMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const quoteId = c.req.param('id')
  const userId = c.get('userId')

  const { data: quoteCard, error } = await supabase
    .from('quote_cards')
    .select('*')
    .eq('id', quoteId)
    .single()

  if (error || !quoteCard) {
    return c.json({ error: 'Quote card not found' }, 404)
  }

  // Increment view count
  await supabase.rpc('increment_quote_card_views', { p_quote_card_id: quoteId })

  return c.json({ quote: quoteCard })
})

/**
 * POST /api/quotes/:id/share
 * Record a share action and return shareable URL
 */
app.post('/api/quotes/:id/share', authMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const quoteId = c.req.param('id')
  const userId = c.get('userId')

  // Verify access and increment share count
  const { data: quoteCard, error } = await supabase
    .from('quote_cards')
    .select('id, quote_text, author_name, author_role, image_url, family_id')
    .eq('id', quoteId)
    .single()

  if (error || !quoteCard) {
    return c.json({ error: 'Quote card not found' }, 404)
  }

  // Increment share count
  await supabase.rpc('increment_quote_card_shares', { p_quote_card_id: quoteId })

  // Generate share URL
  const shareUrl = `${c.env.APP_URL || 'https://storyrd.app'}/share/${quoteId}`

  return c.json({
    url: shareUrl,
    quote: quoteCard.quote_text,
    author: quoteCard.author_name,
    imageUrl: quoteCard.image_url,
  })
})

/**
 * POST /api/quotes/:id/save
 * Record a save action
 */
app.post('/api/quotes/:id/save', authMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const quoteId = c.req.param('id')
  const userId = c.get('userId')

  const { error } = await supabase
    .from('quote_cards')
    .select('id')
    .eq('id', quoteId)
    .single()

  if (error) {
    return c.json({ error: 'Quote card not found' }, 404)
  }

  await supabase.rpc('increment_quote_card_saves', { p_quote_card_id: quoteId })

  return c.json({ success: true })
})

/**
 * DELETE /api/quotes/:id
 * Delete a quote card (owner only)
 */
app.delete('/api/quotes/:id', authMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const quoteId = c.req.param('id')
  const userId = c.get('userId')

  const { data: profile } = await supabase
    .from('profiles')
    .select('id')
    .eq('auth_user_id', userId)
    .single()

  if (!profile) {
    return c.json({ error: 'Profile not found' }, 404)
  }

  const { error } = await supabase
    .from('quote_cards')
    .delete()
    .eq('id', quoteId)
    .eq('created_by', profile.id)

  if (error) {
    return c.json({ error: 'Failed to delete quote card' }, 500)
  }

  return c.json({ success: true })
})

/**
 * Extract a meaningful quote from transcription text
 * Takes first 1-2 sentences, max 280 characters
 */
function extractQuote(transcription: string): string {
  if (!transcription) return ''
  
  // Clean up the text
  let cleaned = transcription.trim()
  
  // Remove common prefixes
  cleaned = cleaned.replace(/^(So|Well|You know|Actually|Like),\s*/i, '')
  
  // Get first 1-2 sentences
  const sentences = cleaned.split(/[.!?]+/).filter(s => s.trim().length > 0)
  let quote = sentences[0] || cleaned
  
  // Add second sentence if short
  if (sentences.length > 1 && quote.length < 100) {
    quote = quote + '. ' + sentences[1]
  }
  
  // Limit to 280 characters (Twitter length)
  if (quote.length > 280) {
    quote = quote.substring(0, 277) + '...'
  }
  
  return quote.trim()
}

export default app
