import { Hono } from 'hono'
import { authMiddleware, profileMiddleware } from '../middleware/auth'
import { createDalleClient } from '../ai/dalle'
import { logger, getUserId } from '../utils/logger'

const app = new Hono()

app.get('/api/stories', authMiddleware, profileMiddleware, async (c) => {
  const route = '/api/stories'
  const method = 'GET'
  const userId = getUserId(c)

  logger.logRequest(route, method, userId)

  const supabase = c.get('supabase')
  const profile = c.get('profile')

  const { data: stories, error } = await supabase
    .from('stories')
    .select(`
      *,
      prompt:prompts(text, category),
      profiles:responses(user_id, source, duration_seconds)
    `)
    .eq('family_id', profile.family_id)
    .order('created_at', { ascending: false })

  if (error) {
    logger.logDBError('SELECT', 'stories', error, { route, userId, familyId: profile.family_id })
    return c.json({ error: error.message }, 500)
  }

  logger.info(`Stories fetched successfully`, { route, userId, count: stories?.length || 0 })
  return c.json(stories)
})

app.get('/api/stories/:id', async (c) => {
  const route = '/api/stories/:id'
  const method = 'GET'
  const userId = getUserId(c)
  const storyId = c.req.param('id')

  logger.logRequest(route, method, userId)

  const supabase = c.get('supabase')

  const { data: story, error } = await supabase
    .from('stories')
    .select(`
      *,
      prompt:prompts(text, category),
      responses(
        id,
        user_id,
        source,
        media_url,
        transcription_text,
        duration_seconds,
        created_at,
        reply_to_response_id,
        profiles(full_name, role, avatar_url)
      )
    `)
    .eq('id', storyId)
    .single()

  if (error || !story) {
    logger.warn(`Story not found`, { route, userId, storyId, error: error?.message })
    return c.json({ error: 'Story not found' }, 404)
  }

  // Extract responses and flatten the nested profile data
  const responses = (story.responses || []).map((response: any) => ({
    id: response.id,
    user_id: response.user_id,
    source: response.source,
    media_url: response.media_url,
    transcription_text: response.transcription_text,
    duration_seconds: response.duration_seconds,
    created_at: response.created_at,
    full_name: response.profiles?.full_name || 'Unknown',
    role: response.profiles?.role || 'member',
    avatar_url: response.profiles?.avatar_url,
    reply_to_response_id: response.reply_to_response_id,
  }))

  // Remove responses from story object to avoid duplication
  const { responses: _, ...storyData } = story

  // Return in the format expected by iOS app (StoryDetailData)
  logger.info(`Story detail fetched successfully`, { route, userId, storyId, responseCount: responses.length })
  return c.json({
    story: {
      id: storyData.id,
      prompt_id: storyData.prompt_id,
      family_id: storyData.family_id,
      title: storyData.title,
      summary_text: storyData.summary_text,
      cover_image_url: storyData.cover_image_url,
      voice_count: storyData.voice_count,
      is_completed: storyData.is_completed,
      created_at: storyData.created_at,
      prompt_text: storyData.prompt?.text,
      prompt_category: storyData.prompt?.category,
    },
    responses,
  })
})

app.post('/api/stories', authMiddleware, profileMiddleware, async (c) => {
  const route = '/api/stories'
  const method = 'POST'
  const userId = getUserId(c)

  logger.logRequest(route, method, userId)

  const supabase = c.get('supabase')
  const profile = c.get('profile')
  const body = await c.req.json()

  const { data: story, error } = await supabase
    .from('stories')
    .insert({
      prompt_id: body.prompt_id,
      family_id: profile.family_id,
      voice_count: 1,
      is_completed: false,
    })
    .select()
    .single()

  if (error) {
    logger.logDBError('INSERT', 'stories', error, { route, userId, familyId: profile.family_id })
    return c.json({ error: error.message }, 500)
  }

  logger.info(`Story created successfully`, { route, userId, storyId: story.id })
  return c.json(story, 201)
})

app.patch('/api/stories/:id/complete', async (c) => {
  const supabase = c.get('supabase')
  const storyId = c.req.param('id')
  const body = await c.req.json()

  const { data, error } = await supabase
    .from('stories')
    .update({
      is_completed: true,
      title: body.title,
      summary_text: body.summary,
      cover_image_url: body.cover_image_url,
      voice_count: body.voice_count,
    })
    .eq('id', storyId)
    .select()
    .single()

  if (error) {
    return c.json({ error: error.message }, 500)
  }

  return c.json(data)
})

// ============================================================================
// PODCAST ENDPOINTS
// ============================================================================

/**
 * Get podcast (audio playlist) for a story
 *
 * Returns all audio clips in order for sequential playback in the app.
 * No backend processing - just returns the URLs and metadata.
 */
app.get('/api/stories/:id/podcast', async (c) => {
  const route = '/api/stories/:id/podcast'
  const method = 'GET'
  const userId = getUserId(c)
  const storyId = c.req.param('id')

  logger.logRequest(route, method, userId)

  const supabase = c.get('supabase')

  const { data: responses, error } = await supabase
    .from('responses')
    .select(`
      id,
      media_url,
      transcription_text,
      duration_seconds,
      created_at,
      profiles(full_name, role, avatar_url)
    `)
    .eq('story_id', storyId)
    .order('created_at', { ascending: true })

  if (error) {
    logger.logDBError('SELECT', 'responses', error, { route, userId, storyId })
    return c.json({ error: error.message }, 500)
  }

  if (!responses || responses.length === 0) {
    logger.warn(`No audio responses found for story`, { route, userId, storyId })
    return c.json({ error: 'No audio responses found' }, 404)
  }

  // Filter to only responses with audio
  const audioClips = responses.filter((r: any) => r.media_url)

  logger.info(`Podcast fetched successfully`, { route, userId, storyId, clipCount: audioClips.length })
  return c.json({
    storyId,
    type: 'playlist',  // Simple playlist, not a processed podcast
    clips: audioClips.map((r: any) => ({
      id: r.id,
      url: r.media_url,
      text: r.transcription_text,
      duration: r.duration_seconds,
      speaker: {
        name: r.profiles?.full_name || 'Unknown',
        role: r.profiles?.role || 'member',
        avatarUrl: r.profiles?.avatar_url,
      },
    })),
    totalDuration: audioClips.reduce((sum: number, r: any) => sum + (r.duration_seconds || 0), 0),
    clipCount: audioClips.length,
  })
})

/**
 * Get podcast status for a story
 *
 * Returns info about whether all responses are ready for playback.
 */
app.get('/api/stories/:id/podcast-status', async (c) => {
  const supabase = c.get('supabase')
  const storyId = c.req.param('id')

  const { data: responses, error } = await supabase
    .from('responses')
    .select('media_url, processing_status, duration_seconds')
    .eq('story_id', storyId)

  if (error) {
    return c.json({ error: error.message }, 500)
  }

  const totalClips = responses?.length || 0
  const readyClips = responses?.filter((r: any) => r.media_url && r.processing_status === 'completed').length || 0
  const totalDuration = responses?.reduce((sum: number, r: any) => sum + (r.duration_seconds || 0), 0) || 0

  return c.json({
    storyId,
    status: readyClips === totalClips && totalClips > 0 ? 'ready' : 'pending',
    readyClips,
    totalClips,
    totalDuration,
    isReady: readyClips === totalClips && totalClips > 0,
  })
})

/**
 * POST /api/stories/:id/generate-podcast
 *
 * Triggers podcast generation for a story.
 * Sends a trigger.dev event to start the background job.
 *
 * Requires: User must be a member of the story's family
 */
app.post('/api/stories/:id/generate-podcast', authMiddleware, profileMiddleware, async (c) => {
  const route = '/api/stories/:id/generate-podcast'
  const method = 'POST'
  const userId = getUserId(c)
  const storyId = c.req.param('id')
  const profile = c.get('profile')

  logger.logRequest(route, method, userId)

  const supabase = c.get('supabase')
  const triggerdev = c.get('triggerdev') as any

  // Verify story belongs to user's family
  const { data: story, error: storyError } = await supabase
    .from('stories')
    .select('id, family_id, prompt_id, podcast_status')
    .eq('id', storyId)
    .single()

  if (storyError || !story) {
    logger.warn(`Story not found for podcast generation`, { route, userId, storyId })
    return c.json({ error: 'Story not found' }, 404)
  }

  if (story.family_id !== profile.family_id) {
    logger.warn(`Unauthorized podcast generation attempt`, { route, userId, storyId, profileFamilyId: profile.family_id, storyFamilyId: story.family_id })
    return c.json({ error: 'Unauthorized' }, 403)
  }

  // Check if podcast is already being generated
  if (story.podcast_status === 'generating' || story.podcast_status === 'regenerating') {
    logger.info(`Podcast already being generated`, { route, userId, storyId, status: story.podcast_status })
    return c.json({
      message: 'Podcast is already being generated',
      status: story.podcast_status,
    }, 202)
  }

  try {
    // Get story responses
    const { data: responses } = await supabase
      .from('responses')
      .select('id, transcription_text')
      .eq('story_id', storyId)

    if (!responses || responses.length === 0) {
      logger.warn(`No responses found for podcast generation`, { route, userId, storyId })
      return c.json({ error: 'No responses found for this story' }, 400)
    }

    // Get prompt text
    const { data: prompt } = await supabase
      .from('prompts')
      .select('text')
      .eq('id', story.prompt_id)
      .single()

    // Send event to trigger.dev
    const event = await triggerdev.sendEvent({
      name: 'story.ready.for.podcast',
      payload: {
        storyId,
        responseIds: responses.map((r: any) => r.id),
        promptText: prompt?.text || '',
      },
    })

    logger.info(`Podcast generation triggered`, {
      route,
      userId,
      storyId,
      eventId: event.id,
      responseCount: responses.length,
    })

    return c.json({
      message: 'Podcast generation started',
      storyId,
      eventId: event.id,
      status: 'generating',
    })

  } catch (error) {
    logger.error(`Failed to trigger podcast generation`, {
      route,
      userId,
      storyId,
      error: error instanceof Error ? error.message : String(error),
    })
    return c.json({ error: 'Failed to start podcast generation' }, 500)
  }
})

// ============================================================================
// DALL-E COVER GENERATION
// ============================================================================

/**
 * POST /api/stories/:id/generate-cover
 *
 * Generate an AI cover image for a story using DALL-E
 *
 * Requires: OPENAI_API_KEY environment variable
 */
app.post('/api/stories/:id/generate-cover', authMiddleware, profileMiddleware, async (c) => {
  const route = '/api/stories/:id/generate-cover'
  const method = 'POST'
  const userId = getUserId(c)
  const storyId = c.req.param('id')
  const profile = c.get('profile')

  logger.logRequest(route, method, userId)

  const supabase = c.get('supabase')

  // Verify story belongs to user's family
  const { data: story, error: storyError } = await supabase
    .from('stories')
    .select('id, title, summary_text, family_id, prompt_id')
    .eq('id', storyId)
    .single()

  if (storyError || !story) {
    logger.warn(`Story not found for cover generation`, { route, userId, storyId })
    return c.json({ error: 'Story not found' }, 404)
  }

  if (story.family_id !== profile.family_id) {
    logger.warn(`Unauthorized cover generation attempt`, { route, userId, storyId, profileFamilyId: profile.family_id, storyFamilyId: story.family_id })
    return c.json({ error: 'Unauthorized' }, 403)
  }

  try {
    // Get prompt text for context
    const { data: prompt } = await supabase
      .from('prompts')
      .select('text')
      .eq('id', story.prompt_id)
      .single()

    // Initialize DALL-E client
    const dalle = createDalleClient({
      apiKey: c.env.OPENAI_API_KEY,
      model: 'dall-e-3',
      size: '1024x1024',
      quality: 'standard',
      style: 'vivid',
    })

    logger.info(`Starting DALL-E cover generation`, { route, userId, storyId })

    // Generate and upload cover
    const { r2Url, revisedPrompt } = await dalle.generateAndUploadCover(
      {
        title: story.title || 'Family Story',
        summary: story.summary_text || prompt?.text || 'A heartwarming family story',
        style: 'warm',
      },
      storyId,
      c.env.AUDIO_BUCKET  // Reusing the same R2 bucket for images
    )

    // Update story with cover URL
    const { error: updateError } = await supabase
      .from('stories')
      .update({ cover_image_url: r2Url })
      .eq('id', storyId)

    if (updateError) {
      logger.logDBError('UPDATE', 'stories', updateError, { route, userId, storyId })
      return c.json({ error: updateError.message }, 500)
    }

    logger.info(`Cover image generated successfully`, { route, userId, storyId, coverUrl: r2Url })
    return c.json({
      success: true,
      coverImageUrl: r2Url,
      revisedPrompt,
    })

  } catch (error) {
    logger.error(`DALL-E generation error`, error, { route, userId, storyId })
    return c.json({
      error: 'Failed to generate cover image',
      details: error instanceof Error ? error.message : 'Unknown error',
    }, 500)
  }
})

export default app

