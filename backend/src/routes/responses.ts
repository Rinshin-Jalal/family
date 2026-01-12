import { Hono } from 'hono'
import { authMiddleware, profileMiddleware } from '../middleware/auth'
import { processResponseTask } from '../../trigger/process-response-task'
import { transcribeResponseTask } from '../../trigger/transcribe-response-task'

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
  const queue = c.get('queue')  // Event queue from bindings (optional)

  try {
    const formData = await c.req.formData()

    // Get the uploaded file (could be audio, text, image, document, etc.)
    const file = formData.get('file') as File || formData.get('audio') as File

    console.log('[responses] File received:', !!file, file?.name, file?.type, file?.size)

    const storyId = formData.get('story_id') as string | null
    const source = (formData.get('source') as string) || 'app_audio'

    console.log('[responses] Source:', source, 'storyId:', storyId)

    // Direct text content (if not uploading a file)
    const textContentDirect = formData.get('text') as string | null

    // Determine file type and process accordingly
    let textContent: string | null = textContentDirect
    let mediaKey: string | null = null
    let mediaUrl: string | null = null
    let processingStatus: 'pending' | 'completed' = 'pending'
    let eventType: 'response.audio.uploaded' | 'response.transcribed' | 'response.ocr.requested' | null = null
    let eventData: any = null

    if (file) {
      const timestamp = Date.now()
      mediaKey = `responses/${profile.id}/${timestamp}_${file.name}`

      // Upload to R2
      await c.env.AUDIO_BUCKET.put(mediaKey, file.stream(), {
        httpMetadata: {
          contentType: file.type,
        },
      })
      
      // Generate R2 URL - use signedUrl in production or custom domain
      // For now, store the key in database and generate signed URLs on retrieval
      // Production: Configure custom domain in Cloudflare R2 settings
      const accountId = c.env.CLOUDFLARE_ACCOUNT_ID || 'development'
      const bucketName = 'family-plus-audio'
      mediaUrl = `https://${bucketName}.r2.cloudflarestorage.com/${mediaKey}`

      // Detect file type by MIME type and extension
      const mimeType = file.type.toLowerCase()
      const fileName = file.name.toLowerCase()

      // TEXT FILES (.txt, .md, text/plain)
      const isTextFile = mimeType.startsWith('text/') ||
                         fileName.endsWith('.txt') ||
                         fileName.endsWith('.md') ||
                         source === 'app_text'

      // AUDIO FILES (audio/*, .m4a, .wav, .mp3, .ogg, etc.)
      const isAudioFile = mimeType.startsWith('audio/') ||
                          fileName.endsWith('.m4a') ||
                          fileName.endsWith('.wav') ||
                          fileName.endsWith('.mp3') ||
                          fileName.endsWith('.ogg') ||
                          fileName.endsWith('.webm')

      // IMAGE FILES (image/*, .jpg, .png, .heic, etc.)
      const isImageFile = mimeType.startsWith('image/')

      // DOCUMENT FILES (application/pdf, .doc, .docx, etc.)
      const isDocumentFile = mimeType === 'application/pdf' ||
                            mimeType.includes('document') ||
                            mimeType.includes('word') ||
                            fileName.endsWith('.pdf') ||
                            fileName.endsWith('.doc') ||
                            fileName.endsWith('.docx')

      if (isTextFile) {
        // Text: extract immediately
        textContent = await file.text()
        processingStatus = 'completed'
        eventType = 'response.transcribed'
        eventData = {
          responseId: '',  // Will set after DB insert
          storyId,
          transcriptionText: textContent,
          durationSeconds: 0,
        }
      } else if (isAudioFile) {
        // Audio: needs transcription
        processingStatus = 'pending'
        eventType = 'response.audio.uploaded'
        eventData = {
          responseId: '',  // Will set after DB insert
          audioKey: mediaKey,
          audioUrl: mediaUrl,
          fileSize: file.size,
          duration: 0,
          mimeType: file.type,
        }
      } else if (isImageFile || isDocumentFile) {
        // Image/Document: needs OCR
        processingStatus = 'pending'
        eventType = 'response.ocr.requested'  // New event type for OCR
        eventData = {
          responseId: '',  // Will set after DB insert
          fileKey: mediaKey,
          fileUrl: mediaUrl,
          fileSize: file.size,
          mimeType: file.type,
          fileType: isImageFile ? 'image' : 'document',
        }
      } else {
        // Unknown file type: treat as needing processing
        console.warn(`[responses] Unknown file type: ${mimeType}, treating as pending`)
        processingStatus = 'pending'
        eventType = null  // Will need manual processing
      }
    }

    // Create response record in database
    const { data: response, error } = await supabase
      .from('responses')
      .insert({
        story_id: storyId,
        user_id: profile.id,
        source: source,
        media_url: mediaUrl,
        transcription_text: textContent,
        processing_status: processingStatus,
      })
      .select()
      .single()

    if (error) {
      console.error('[responses] Database insert error:', error)
      return c.json({ error: error.message }, 500)
    }

    // Trigger background tasks based on response type
    console.log('[responses] Triggering background tasks for response', response.id)

    try {
      // Case 1: Audio file - trigger transcription
      if (mediaUrl && !textContent && processingStatus === 'pending') {
        console.log('[responses] Audio file detected - triggering transcription task...')

        const audioKey = mediaKey || mediaUrl.split('https://your-r2-domain.com/')[1]
        const handle = await transcribeResponseTask.trigger({
          responseId: response.id,
          audioKey: audioKey || mediaKey,
          audioUrl: mediaUrl,
          userId: profile.id,
          familyId: profile.family_id,
        })
        console.log('[responses] ✅ Transcription task triggered:', handle.id)
      }

      // Case 2: Text content with NO story_id - create new story
      else if (textContent && !storyId) {
        console.log('[responses] Text content without story_id - triggering story creation task...')

        const handle = await processResponseTask.trigger({
          responseId: response.id,
          transcriptionText: textContent,
          familyId: profile.family_id,
          userId: profile.id,
        })
        console.log('[responses] ✅ Story creation task triggered:', handle.id)
      }

      // Case 3: Text content added to existing story - trigger quote generation only
      // Note: Wisdom tagging is NOT triggered here to avoid re-processing all responses
      // Wisdom should be triggered selectively when appropriate (e.g., story completion, major updates)
      else if (textContent && storyId) {
        console.log('[responses] Text content for existing story - triggering quote task only...')

        // Trigger quote generation (always run for new content)
        const { generateQuoteTask } = await import('../../trigger/quote-task')
        const quoteHandle = await generateQuoteTask.trigger({
          responseId: response.id,
          storyId: storyId,
          triggeredBy: 'response.transcribed',
        })
        console.log('[responses] ✅ Quote generation task triggered:', quoteHandle.id)

        // Wisdom tagging skipped - would re-process all responses in the story
        // Use manual trigger or separate endpoint if you want to refresh wisdom tags
      }
    } catch (err) {
      console.error('[responses] ❌ Failed to trigger background task:', err)
      console.error('[responses] Error details:', JSON.stringify(err))
      // Don't return error - response was already saved
    }

    // Return immediately with camelCase keys for Swift
    return c.json({
      id: response.id,
      storyId: response.story_id,
      userId: response.user_id,
      source: response.source,
      mediaUrl: response.media_url,
      transcriptionText: response.transcription_text,
      durationSeconds: response.duration_seconds,
      processingStatus: response.processing_status || 'pending',
      createdAt: response.created_at,
    }, 201)
  } catch (err) {
    console.error('[responses] Unexpected error:', err)
    return c.json({ error: 'Failed to process response' }, 500)
  }
})

/**
 * Manually trigger transcription for a response
 *
 * This endpoint triggers the trigger.dev transcription task.
 */
app.post('/api/responses/:id/transcribe', authMiddleware, profileMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const profile = c.get('profile')
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

  // 3. Trigger transcription task with trigger.dev
  try {
    const handle = await transcribeResponseTask.trigger({
      responseId: response.id,
      audioKey,
      audioUrl: response.media_url,
      userId: profile.id,
      familyId: profile.family_id,
    })

    return c.json({
      success: true,
      message: 'Transcription started',
      taskId: handle.id,
      responseId: response.id,
    })
  } catch (error) {
    console.error('[responses] Failed to trigger transcription:', error)
    return c.json({ error: 'Failed to start transcription' }, 500)
  }
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
