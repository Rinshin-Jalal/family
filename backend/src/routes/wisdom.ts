// src/routes/wisdom.ts
// Wisdom Tags, Search, and Request System - EVENT DRIVEN
//
// Flow: API receives request -> publishes event -> returns 202 Accepted
// Background workers process events asynchronously

import { Hono } from 'hono';
import { authMiddleware } from '../middleware/auth';
import { createQwenTurboClient } from '../ai/llm';
import { EmbeddingsClient } from '../ai/embeddings';
import { logger, getUserId } from '../utils/logger';

const app = new Hono<{ Bindings: any; Variables: any }>();
/**
 * POST /api/wisdom/tag/:storyId
 * Publishes event: wisdom.story.tag.requested
 * Returns: 202 Accepted (processing happens in background)
 */
app.post('/api/wisdom/tag/:storyId', authMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const storyId = c.req.param('storyId')
  const userId = c.get('userId')

  // Verify story exists
  const { data: story, error } = await supabase
    .from('stories')
    .select('id, family_id')
    .eq('id', storyId)
    .single()

  if (error || !story) {
    return c.json({ error: 'Story not found' }, 404)
  }

  return c.json({
    status: 'processing',
    message: 'Story tagging queued',
    storyId,
  }, 202)
})

/**
 * GET /api/wisdom/search
 * Search stories by question (still synchronous - searches DB directly)
 */
app.get('/api/wisdom/search', authMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const searchQuery = c.req.query('q')
  const limit = parseInt(c.req.query('limit') || '10')

  if (!searchQuery) {
    return c.json({ error: 'Search query required' }, 400)
  }

  const { data: profile } = await supabase
    .from('profiles')
    .select('id, family_id')
    .eq('auth_user_id', c.get('userId'))
    .single()

  if (!profile) {
    return c.json({ error: 'Profile not found' }, 404)
  }

  // Use PostgreSQL full-text search via RPC
  const { data: stories, error } = await supabase
    .rpc('search_wisdom_by_query', {
      p_family_id: profile.family_id,
      p_search_query: searchQuery,
      p_limit: limit,
    })

   if (error) {
     // Fallback to simple search
     const { data: fallback } = await supabase
       .from('stories')
       .select('id, title, summary_text, cover_image_url')
       .eq('family_id', profile.family_id)
       .ilike('summary_text', `%${searchQuery}%`)
       .limit(limit)

     return c.json({ query: searchQuery, stories: fallback || [], count: fallback?.length || 0 })
   }



  return c.json({ query: searchQuery, stories: stories || [], count: stories?.length || 0 })
})

/**
 * GET /api/wisdom/search/responses
 * Search responses by wisdom tags (NEW - response-level search)
 * Searches across response_tags for emotion_tags, situation_tags, lesson_tags, etc.
 */
app.get('/api/wisdom/search/responses', authMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const searchQuery = c.req.query('q')
  const limit = parseInt(c.req.query('limit') || '10')

  if (!searchQuery) {
    return c.json({ error: 'Search query required' }, 400)
  }

  const { data: profile } = await supabase
    .from('profiles')
    .select('id, family_id')
    .eq('auth_user_id', c.get('userId'))
    .single()

  if (!profile) {
    return c.json({ error: 'Profile not found' }, 404)
  }

  // Search responses by wisdom tags using PostgreSQL
  const { data: responses, error } = await supabase
    .rpc('search_wisdom_in_responses', {
      p_family_id: profile.family_id,
      p_search_query: searchQuery,
      p_limit: limit,
    })

  if (error) {
    return c.json({ error: error.message }, 500)
  }

      return c.json({ query: searchQuery, responses: responses || [], count: responses?.length || 0 })
  })


/**
 * POST /api/wisdom/request
 * Publishes event: wisdom.request.created
 * Returns: 202 Accepted (notifications sent in background)
 */
app.post('/api/wisdom/request', authMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const eventPublisher = c.get('eventPublisher')
  const body = await c.req.json()
  const { question, target_profile_ids, related_story_id } = body
  const userId = c.get('userId')

  if (!question || !target_profile_ids?.length) {
    return c.json({ error: 'Question and targets required' }, 400)
  }

  // Get requester info
  const { data: requester } = await supabase
    .from('profiles')
    .select('id, family_id, full_name')
    .eq('auth_user_id', userId)
    .single()

  if (!requester) {
    return c.json({ error: 'Requester not found' }, 404)
  }

  // Verify targets exist and belong to same family
  const { data: targets, error: targetsError } = await supabase
    .from('profiles')
    .select('id, full_name, phone_number')
    .in('id', target_profile_ids)

  if (targetsError || !targets?.length) {
    return c.json({ error: 'Targets not found' }, 400)
  }

  // Create request record
  const { data: request, error: createError } = await supabase
    .from('wisdom_requests')
    .insert({
      question,
      requester_id: requester.id,
      target_profile_ids,
      related_story_id,
      status: 'pending',
    })
    .select()
    .single()

  if (createError) {
    return c.json({ error: 'Failed to create request' }, 500)
  }

  // Publish event - background worker will send notifications
  await eventPublisher.publish('wisdom.request.created', {
    requestId: request.id,
    question,
    requesterId: requester.id,
    requesterName: requester.full_name || 'Family Member',
    targetProfileIds: target_profile_ids,
    relatedStoryId: related_story_id,
  }, { userId, familyId: requester.family_id })

  return c.json({
    status: 'processing',
    message: 'Wisdom request created, notifications being sent',
    request: {
      id: request.id,
      question: request.question,
      status: request.status,
    },
  }, 202)
})

/**
 * GET /api/wisdom/requests/pending
 * Get pending requests for current user
 */
app.get('/api/wisdom/requests/pending', authMiddleware, async (c) => {
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

  const { data: requests } = await supabase
    .from('wisdom_requests')
    .select('id, question, requester:profiles!requester_id(full_name), created_at, expires_at')
    .contains('target_profile_ids', [profile.id])
    .eq('status', 'pending')
    .gt('expires_at', new Date().toISOString())
    .order('created_at', { ascending: false })

  return c.json({ requests: requests || [], count: requests?.length || 0 })
})

/**
 * PATCH /api/wisdom/request/:requestId/respond
 * Accept or decline a wisdom request
 */
app.patch('/api/wisdom/request/:requestId/respond', authMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const requestId = c.req.param('requestId')
  const body = await c.req.json()
  const { action } = body // 'accept' or 'decline'
  const userId = c.get('userId')

  if (!['accept', 'decline'].includes(action)) {
    return c.json({ error: 'Invalid action' }, 400)
  }

  const { data: profile } = await supabase
    .from('profiles')
    .select('id')
    .eq('auth_user_id', userId)
    .single()

  if (!profile) {
    return c.json({ error: 'Profile not found' }, 404)
  }

  const { data: request } = await supabase
    .from('wisdom_requests')
    .select('*')
    .eq('id', requestId)
    .single()

  if (!request || !request.target_profile_ids.includes(profile.id)) {
    return c.json({ error: 'Request not found or unauthorized' }, 404)
  }

  const newStatus = action === 'accept' ? 'accepted' : 'declined'
  
  await supabase
    .from('wisdom_requests')
    .update({ status: newStatus, updated_at: new Date().toISOString() })
    .eq('id', requestId)

  return c.json({ success: true, requestId, status: newStatus })
})

/**
 * GET /api/wisdom/request
 * Publishes event: wisdom.request.created
 * Returns: 202 Accepted (notifications sent in background)
 */
// Story tags endpoint removed - story_tags table no longer exists

/**
 * PUT /api/wisdom/tags/:storyId (DEPRECATED - story_tags table removed)
 */
// Story tags endpoints removed - story_tags table no longer exists

/**
 * POST /api/wisdom/summarize
 * Publishes event: wisdom.summary.requested
 * Returns: 202 Accepted (AI processing in background)
 */
app.post('/api/wisdom/summarize', authMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const eventPublisher = c.get('eventPublisher')
  const body = await c.req.json()
  const { question, story_ids } = body
  const userId = c.get('userId')

  if (!question || !story_ids?.length) {
    return c.json({ error: 'Question and story IDs required' }, 400)
  }

  const { data: profile } = await supabase
    .from('profiles')
    .select('id, family_id')
    .eq('auth_user_id', userId)
    .single()

  if (!profile) {
    return c.json({ error: 'Profile not found' }, 404)
  }

  // Verify all stories belong to user's family
  const { data: stories, error } = await supabase
    .from('stories')
    .select('id')
    .in('id', story_ids)
    .eq('family_id', profile.family_id)

  if (error || stories?.length !== story_ids.length) {
    return c.json({ error: 'Stories not found' }, 404)
  }

  // Publish summary request event
  await eventPublisher.publish('wisdom.summary.requested', {
    storyIds: story_ids,
    question,
    userId,
  }, { userId, familyId: profile.family_id })

  return c.json({
    status: 'processing',
    message: 'Wisdom summary generation queued',
    storyCount: story_ids.length,
  }, 202)
})

/**
 * POST /api/wisdom/kid-friendly/:storyId
 * Generate kid-friendly version
 */
app.post('/api/wisdom/kid-friendly/:storyId', authMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const storyId = c.req.param('storyId')
  const body = await c.req.json()
  const kidAge = body.kid_age || 8

  // Note: This is a simpler operation that could be done synchronously
  // or also event-driven for more complex AI processing
  
  const { data: story, error } = await supabase
    .from('stories')
    .select('id, title, responses(transcription_text, profiles(full_name, role))')
    .eq('id', storyId)
    .single()

  if (error || !story) {
    return c.json({ error: 'Story not found' }, 404)
  }

  // For now, return placeholder - would publish event for AI processing
  return c.json({
    status: 'placeholder',
    message: 'Kid-friendly generation would be event-driven',
    storyId,
    kidAge,
  }, 202)
})

/**
 * GET /api/wisdom/summary/:storyId
 * Get existing wisdom summary
 */
app.get('/api/wisdom/summary/:storyId', authMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const storyId = c.req.param('storyId')

  const { data: summary } = await supabase
    .from('wisdom_summaries')
    .select('*')
    .eq('story_id', storyId)
    .single()

  if (!summary) {
    return c.json({ storyId, summary: null, message: 'No summary' })
  }

  return c.json({
    storyId,
    summary: {
      text: summary.summary_text,
      whatHappened: summary.what_happened,
      whatLearned: summary.what_learned,
      guidance: summary.guidance,
      generation: summary.generation,
      yearRange: summary.year_range,
      createdAt: summary.created_at,
    },
  })
})

/**
 * GET /api/wisdom/requests/pending
 * Get pending requests for current user
 */
app.get('/api/wisdom/topics/discussion', authMiddleware, async (c) => {
  const route = '/api/wisdom/topics/discussion'
  const method = 'GET'
  const userId = getUserId(c)

  logger.logRequest(route, method, userId)

  const supabase = c.get('supabase')

  const { data: profile } = await supabase
    .from('profiles')
    .select('id, family_id')
    .eq('auth_user_id', userId)
    .single()

  if (!profile) {
    logger.warn(`Profile not found for discussion topics`, { route, userId })
    return c.json({ error: 'Profile not found' }, 404)
  }

  // Fetch family stories
  const { data: stories, error: storiesError } = await supabase
    .from('stories')
    .select(`
      id,
      title,
      summary_text,
      voice_count,
      is_completed
    `)
    .eq('family_id', profile.family_id)
    .order('created_at', { ascending: false })
    .limit(20)

  if (storiesError) {
    logger.logDBError('SELECT', 'stories', storiesError, { route, userId, familyId: profile.family_id })
  }

  if (!stories?.length) {
    logger.info(`No stories found, returning empty topics`, { route, userId, familyId: profile.family_id })
    return c.json({
      topics: [],
    })
  }

  try {
    // Initialize LLM client
    const llm = createQwenTurboClient({
      openaiApiKey: c.env.AWS_BEARER_TOKEN_BEDROCK,
      bedrockRegion: c.env.AWS_REGION || 'us-east-1',
    })

    logger.info(`Generating AI discussion topics`, { route, userId, storyCount: stories.length })

    // Format stories for AI
    const familyStories = stories.map((s: any) => ({
      title: s.title || 'Untitled Story',
      summaryText: s.summary_text || '',
      voiceCount: s.voice_count || 0,
      tags: [], // story_tags removed
    }))

    // Generate topics using AI
    const result = await llm.generateDiscussionTopics(familyStories)

    logger.info(`Discussion topics generated successfully`, { route, userId, topicCount: result.topics.length })
    return c.json({
      topics: result.topics.slice(0, 5),
      storyCount: stories.length,
    })
  } catch (error) {
    logger.error(`Failed to generate discussion topics`, error, { route, userId, familyId: profile.family_id })
    return c.json({ error: 'Failed to generate topics' }, 500)
  }
})

/**
 * POST /api/wisdom/search/semantic
 * PGVECTOR-powered semantic search
 * Uses pre-computed embeddings stored in database for instant search
 */
app.post('/api/wisdom/search/semantic', authMiddleware, async (c) => {
  const route = '/api/wisdom/search/semantic'
  const method = 'POST'
  const userId = getUserId(c)

  logger.logRequest(route, method, userId)

  const supabase = c.get('supabase')
  const body = await c.req.json()
  const { query, limit = 10 } = body

  if (!query || query.length < 3) {
    logger.warn(`Invalid semantic search query`, { route, userId, queryLength: query?.length })
    return c.json({ error: 'Query must be at least 3 characters' }, 400)
  }

  const { data: profile } = await supabase
    .from('profiles')
    .select('id, family_id')
    .eq('auth_user_id', userId)
    .single()

  if (!profile) {
    logger.warn(`Profile not found for semantic search`, { route, userId })
    return c.json({ error: 'Profile not found' }, 404)
  }

  try {
    // Initialize embeddings client
    const embeddings = new EmbeddingsClient({
        accessKeyId: c.env.AWS_ACCESS_KEY_ID,
        secretAccessKey: c.env.AWS_SECRET_ACCESS_KEY,
        sessionToken: c.env.AWS_SESSION_TOKEN,
        region: c.env.BEDROCK_REGION,
    })

    logger.info(`Generating query embedding`, { route, userId, queryLength: query.length })

    // Generate embedding for query (only 1 API call!)
    const queryEmbedding = await embeddings.embed(query)

    // Convert to PostgreSQL vector format
    const pgVector = '[' + queryEmbedding.embedding.join(', ') + ']'

    logger.info(`Searching with pgvector`, { route, userId })

    const { data: responses, error: responsesError } = await supabase
      .rpc('semantic_search_responses', {
        p_family_id: profile.family_id,
        p_query_embedding: pgVector as any,
        p_limit: limit,
        p_min_similarity: 0.3,
      })

    if (responsesError) {
      logger.error(`Response search error`, { route, userId, error: responsesError })
    }

    const results = (responses || []).map((response: any) => ({
      id: response.response_id,
      type: 'response',
      title: (response.transcription_text || '').substring(0, 80) + '...',
      content: response.transcription_text || '',
      author: response.author_name,
      role: response.author_role,
      storyId: response.story_id,
      similarity: response.similarity,
      createdAt: response.created_at,
    }))

    logger.info(`Semantic search completed (pgvector)`, {
      route,
      userId,
      query,
      resultCount: results.length,
    })

    return c.json({
      query,
      results,
      count: results.length,
    })
  } catch (error) {
    logger.error(`Semantic search failed`, error, { route, userId, query })
    return c.json({ error: 'Search failed' }, 500)
  }
})

export default app
