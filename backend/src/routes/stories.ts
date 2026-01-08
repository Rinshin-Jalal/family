import { Hono } from 'hono'
import { authMiddleware, profileMiddleware } from '../middleware/auth'
import { createDalleClient } from '../ai/dalle'

const app = new Hono()

app.get('/api/stories', authMiddleware, profileMiddleware, async (c) => {
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
    return c.json({ error: error.message }, 500)
  }

  return c.json(stories)
})

app.get('/api/stories/:id', async (c) => {
  const supabase = c.get('supabase')
  const storyId = c.req.param('id')

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
        profiles(full_name, role, avatar_url)
      )
    `)
    .eq('id', storyId)
    .single()

  if (error || !story) {
    return c.json({ error: 'Story not found' }, 404)
  }

  return c.json(story)
})

app.post('/api/stories', authMiddleware, profileMiddleware, async (c) => {
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
    return c.json({ error: error.message }, 500)
  }

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
  const supabase = c.get('supabase')
  const storyId = c.req.param('id')

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
    return c.json({ error: error.message }, 500)
  }

  if (!responses || responses.length === 0) {
    return c.json({ error: 'No audio responses found' }, 404)
  }

  // Filter to only responses with audio
  const audioClips = responses.filter((r: any) => r.media_url)

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
  const supabase = c.get('supabase')
  const storyId = c.req.param('id')
  const profile = c.get('profile')

  // Verify story belongs to user's family
  const { data: story, error: storyError } = await supabase
    .from('stories')
    .select('id, title, summary_text, family_id, prompt_id')
    .eq('id', storyId)
    .single()

  if (storyError || !story) {
    return c.json({ error: 'Story not found' }, 404)
  }

  if (story.family_id !== profile.family_id) {
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
      return c.json({ error: updateError.message }, 500)
    }

    return c.json({
      success: true,
      coverImageUrl: r2Url,
      revisedPrompt,
    })

  } catch (error) {
    console.error('DALL-E generation error:', error)
    return c.json({
      error: 'Failed to generate cover image',
      details: error instanceof Error ? error.message : 'Unknown error',
    }, 500)
  }
})

export default app

