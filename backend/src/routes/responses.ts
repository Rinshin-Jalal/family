import { Hono } from 'hono'
import { authMiddleware, profileMiddleware } from '../middleware/auth'

const app = new Hono()

/**
 * Submit a response (audio or text) to a prompt
 *
 * OLD: Synchronous - uploaded to R2, returned immediately
 * NEW: Event-driven - uploads to R2, publishes event, returns immediately
 *
 * The transcription happens asynchronously in the background worker.
 */
app.post('/api/responses', authMiddleware, profileMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const profile = c.get('profile')
  const queue = c.get('queue')  // Event queue from bindings

  const formData = await c.req.formData()
  const audioFile = formData.get('audio') as File
  const promptId = formData.get('prompt_id') as string
  const storyId = formData.get('story_id') as string | null
  const source = formData.get('source') as 'app_audio' | 'app_text' | 'phone_ai'

  // 1. Upload audio to R2 (still synchronous - must happen before DB record)
  let audioKey: string | null = null
  let mediaUrl: string | null = null

  if (audioFile) {
    const timestamp = Date.now()
    audioKey = `responses/${profile.id}/${timestamp}_${audioFile.name}`

    await c.env.AUDIO_BUCKET.put(audioKey, audioFile.stream(), {
      httpMetadata: {
        contentType: audioFile.type,
      },
    })

    mediaUrl = `https://your-r2-domain.com/${audioKey}`
  }

  // 2. Create response record in database
  const { data: response, error } = await supabase
    .from('responses')
    .insert({
      prompt_id: promptId,
      story_id: storyId,
      user_id: profile.id,
      source: source,
      media_url: mediaUrl,
      processing_status: 'pending',  // Will be processed by event handler
    })
    .select()
    .single()

  if (error) {
    return c.json({ error: error.message }, 500)
  }

  // 3. Publish event to trigger background processing
  if (audioKey && mediaUrl) {
    // Publish response.audio.uploaded event
    await queue.send({
      type: 'response.audio.uploaded',
      data: {
        responseId: response.id,
        audioKey,
        audioUrl: mediaUrl,
        fileSize: audioFile.size,
        duration: 0,  // Will be calculated by handler
        mimeType: audioFile.type,
      },
      metadata: {
        userId: profile.id,
        familyId: profile.family_id,
        source: 'api',
      },
    })
  }

  // 4. Return immediately - processing happens in background
  return c.json({
    ...response,
    processingStatus: 'pending',  // Client can poll for updates
  }, 201)
})

/**
 * Manually trigger transcription for a response
 *
 * This endpoint is kept for backward compatibility but internally
 * it just publishes the same event that the upload handler would.
 */
app.post('/api/responses/:id/transcribe', async (c) => {
  const supabase = c.get('supabase')
  const queue = c.get('queue')
  const responseId = c.req.param('id')

  // 1. Get the response
  const { data: response } = await supabase
    .from('responses')
    .select('*')
    .eq('id', responseId)
    .single()

  if (!response) {
    return c.json({ error: 'Response not found' }, 404)
  }

  // 2. Extract audio key from media_url
  // Assumes format: https://your-r2-domain.com/{key}
  const audioKey = response.media_url?.split('https://your-r2-domain.com/')[1]

  if (!audioKey) {
    return c.json({ error: 'No audio file found' }, 400)
  }

  // 3. Publish event to trigger transcription
  await queue.send({
    type: 'response.audio.uploaded',
    data: {
      responseId: response.id,
      audioKey,
      audioUrl: response.media_url,
      fileSize: 0,  // Unknown
      duration: 0,  // Unknown
      mimeType: 'audio/wav',  // Default assumption
    },
    metadata: {
      source: 'api',
    },
  })

  // 4. Return immediately
  return c.json({
    message: 'Transcription queued',
    responseId,
    status: 'pending',
  })
})

/**
 * Get responses for a story
 *
 * Shows current status of responses (pending, completed, failed)
 */
app.get('/api/stories/:storyId/responses', async (c) => {
  const supabase = c.get('supabase')
  const storyId = c.req.param('storyId')

  const { data: responses, error } = await supabase
    .from('responses')
    .select(`
      id,
      processing_status,
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

  return c.json(responses)
})

export default app
