import { Hono } from 'hono'
import { authMiddleware, profileMiddleware } from '../middleware/auth'

const app = new Hono()

app.post('/api/responses', authMiddleware, profileMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const profile = c.get('profile')

  const formData = await c.req.formData()
  const audioFile = formData.get('audio') as File
  const promptId = formData.get('prompt_id') as string
  const storyId = formData.get('story_id') as string | null
  const source = formData.get('source') as 'app_audio' | 'app_text' | 'phone_ai'

  let mediaUrl: string | null = null

  if (audioFile) {
    const timestamp = Date.now()
    const key = `responses/${profile.id}/${timestamp}_${audioFile.name}`

    await c.env.AUDIO_BUCKET.put(key, audioFile.stream(), {
      httpMetadata: {
        contentType: audioFile.type,
      },
    })

    mediaUrl = `https://your-r2-domain.com/${key}`
  }

  const { data: response, error } = await supabase
    .from('responses')
    .insert({
      prompt_id: promptId,
      story_id: storyId,
      user_id: profile.id,
      source: source,
      media_url: mediaUrl,
      processing_status: 'pending',
    })
    .select()
    .single()

  if (error) {
    return c.json({ error: error.message }, 500)
  }

  return c.json(response, 201)
})

app.post('/api/responses/:id/transcribe', async (c) => {
  const supabase = c.get('supabase')
  const responseId = c.req.param('id')

  const { data: response } = await supabase
    .from('responses')
    .select('*')
    .eq('id', responseId)
    .single()

  if (!response) {
    return c.json({ error: 'Response not found' }, 404)
  }

  const { data: updated, error } = await supabase
    .from('responses')
    .update({
      transcription_text: 'Transcription placeholder',
      duration_seconds: 30,
      processing_status: 'completed',
    })
    .eq('id', responseId)
    .select()
    .single()

  if (error) {
    return c.json({ error: error.message }, 500)
  }

  return c.json(updated)
})

export default app

