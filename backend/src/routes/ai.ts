import { Hono } from 'hono'
import { authMiddleware } from '../middleware/auth'

const app = new Hono()

/**
 * Complete a story with AI synthesis
 *
 * OLD: Synchronous - LLM call blocks HTTP response
 * NEW: Event-driven - publishes event, returns immediately
 *
 * The AI synthesis happens asynchronously in the background worker.
 */
app.post('/api/ai/complete-story', authMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const queue = c.get('queue')
  const body = await c.req.json()

  const { story_id } = body

  // 1. Verify story exists and fetch responses
  const { data: story, error: storyError } = await supabase
    .from('stories')
    .select(`
      *,
      prompt:prompts(text),
      responses(
        id,
        transcription_text,
        profiles(full_name, role, avatar_url)
      )
    `)
    .eq('id', story_id)
    .single()

  if (storyError || !story) {
    return c.json({ error: 'Story not found' }, 404)
  }

  // 2. Verify all responses are transcribed
  const hasPending = story.responses.some(
    (r: any) => !r.transcription_text || r.transcription_text === ''
  )

  if (hasPending) {
    return c.json({
      error: 'Not all responses are transcribed yet',
      pendingCount: story.responses.filter((r: any) => !r.transcription_text).length,
    }, 400)
  }

  // 3. Publish event to trigger AI synthesis
  await queue.send({
    type: 'ai.synthesis.started',
    data: {
      storyId: story_id,
      responseCount: story.responses.length,
      promptText: story.prompt?.text || '',
    },
    metadata: {
      source: 'api',
    },
  })

  // 4. Return immediately - synthesis happens in background
  return c.json({
    message: 'Story synthesis queued',
    storyId: story_id,
    status: 'processing',
  })
})

/**
 * Get the status of a story synthesis
 *
 * Clients can poll this endpoint to check if synthesis is complete.
 */
app.get('/api/stories/:storyId/synthesis-status', async (c) => {
  const supabase = c.get('supabase')
  const storyId = c.req.param('storyId')

  const { data: story, error } = await supabase
    .from('stories')
    .select('id, is_completed, title, summary_text, cover_image_url, created_at')
    .eq('id', storyId)
    .single()

  if (error || !story) {
    return c.json({ error: 'Story not found' }, 404)
  }

  return c.json({
    storyId: story.id,
    status: story.is_completed ? 'completed' : 'processing',
    title: story.title,
    summary: story.summary_text,
    coverImageUrl: story.cover_image_url,
    completedAt: story.is_completed ? new Date().toISOString() : null,
  })
})

export default app
