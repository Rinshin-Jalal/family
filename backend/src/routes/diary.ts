import { Hono } from 'hono'
import { authMiddleware, profileMiddleware } from '../middleware/auth'
import { generateStorageKey } from '../ai/r2'

const app = new Hono()

/**
 * Upload diary images for OCR processing
 *
 * Accepts multiple images (up to 10), uploads to R2, creates database records,
 * and triggers async OCR processing via event queue.
 */
app.post('/api/diary/upload', authMiddleware, profileMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const profile = c.get('profile')
  const queue = c.get('queue')

  const formData = await c.req.formData()
  const source = formData.get('source') as string || 'diary'
  const pageCount = parseInt(formData.get('page_count') as string || '0', 10)

  // Get all image files from form data
  const imageFiles: File[] = []
  for (const [key, value] of formData.entries()) {
    if (key === 'images[]' && value instanceof File) {
      imageFiles.push(value)
    }
  }

  if (imageFiles.length === 0) {
    return c.json({ error: 'No images provided' }, 400)
  }

  if (imageFiles.length > 10) {
    return c.json({ error: 'Maximum 10 images allowed per upload' }, 400)
  }

  // 1. Create diary_uploads record
  const { data: upload, error: uploadError } = await supabase
    .from('diary_uploads')
    .insert({
      family_id: profile.family_id,
      user_id: profile.id,
      source,
      page_count: imageFiles.length,
      processing_status: 'uploading',
    })
    .select()
    .single()

  if (uploadError) {
    return c.json({ error: uploadError.message }, 500)
  }

  // 2. Upload images to R2 and create diary_images records
  const imageUrls: string[] = []
  const imageRecords: any[] = []

  for (let i = 0; i < imageFiles.length; i++) {
    const file = imageFiles[i]
    const imageKey = generateStorageKey('image', profile.id, `diary_${upload.id}_page_${i}.jpg`)

    // Upload to R2
    const buffer = await file.arrayBuffer()
    await c.env.AUDIO_BUCKET.put(imageKey, buffer, {
      httpMetadata: {
        contentType: file.type || 'image/jpeg',
      },
    })

    const imageUrl = `https://your-r2-domain.com/${imageKey}`
    imageUrls.push(imageUrl)

    imageRecords.push({
      upload_id: upload.id,
      image_url: imageUrl,
      image_key: imageKey,
      page_order: i,
      file_size_bytes: file.size,
      processing_status: 'pending',
    })
  }

  // 3. Insert diary_images records
  const { error: imagesError } = await supabase
    .from('diary_images')
    .insert(imageRecords)

  if (imagesError) {
    // Rollback: delete upload record
    await supabase.from('diary_uploads').delete().eq('id', upload.id)
    return c.json({ error: imagesError.message }, 500)
  }

  // 4. Update upload status
  await supabase
    .from('diary_uploads')
    .update({ processing_status: 'pending' })
    .eq('id', upload.id)

  // 5. Return immediately - client will trigger OCR separately
  return c.json({
    upload_id: upload.id,
    image_urls: imageUrls,
    status: 'pending',
    page_count: imageFiles.length,
  }, 201)
})

/**
 * Trigger OCR processing for uploaded diary images
 *
 * Publishes event to queue for async processing via OpenAI Vision API
 */
app.post('/api/diary/:uploadId/ocr', authMiddleware, profileMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const profile = c.get('profile')
  const queue = c.get('queue')
  const uploadId = c.req.param('uploadId')

  // 1. Get upload record
  const { data: upload, error } = await supabase
    .from('diary_uploads')
    .select('*, diary_images(*)')
    .eq('id', uploadId)
    .eq('user_id', profile.id)
    .single()

  if (error || !upload) {
    return c.json({ error: 'Upload not found' }, 404)
  }

  if (upload.processing_status === 'processing') {
    return c.json({ error: 'OCR already in progress' }, 400)
  }

  if (upload.processing_status === 'completed') {
    return c.json({
      upload_id: uploadId,
      status: 'completed',
      message: 'OCR already completed',
    })
  }

  // 2. Update status to processing
  await supabase
    .from('diary_uploads')
    .update({ processing_status: 'processing' })
    .eq('id', uploadId)

  // 3. Publish event to trigger OCR
  await queue.send({
    type: 'diary.ocr.requested',
    data: {
      uploadId,
      images: upload.diary_images.map((img: any) => ({
        id: img.id,
        imageUrl: img.image_url,
        imageKey: img.image_key,
        pageOrder: img.page_order,
      })),
    },
    metadata: {
      userId: profile.id,
      familyId: profile.family_id,
      source: 'api',
    },
  })

  return c.json({
    upload_id: uploadId,
    status: 'processing',
    estimated_time_ms: upload.diary_images.length * 3000, // ~3s per page
  })
})

/**
 * Get OCR processing status
 *
 * Client polls this endpoint to check progress and get results
 */
app.get('/api/diary/:uploadId/status', authMiddleware, profileMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const profile = c.get('profile')
  const uploadId = c.req.param('uploadId')

  // Get upload with pages
  const { data: upload, error } = await supabase
    .from('diary_uploads')
    .select('*, diary_images(*)')
    .eq('id', uploadId)
    .single()

  if (error || !upload) {
    return c.json({ error: 'Upload not found' }, 404)
  }

  // Check user has access (same family)
  if (upload.family_id !== profile.family_id) {
    return c.json({ error: 'Access denied' }, 403)
  }

  // Build response
  const response: any = {
    upload_id: uploadId,
    status: upload.processing_status,
    page_count: upload.page_count,
  }

  if (upload.processing_status === 'completed') {
    response.pages = upload.diary_images
      .sort((a: any, b: any) => a.page_order - b.page_order)
      .map((img: any) => ({
        page_index: img.page_order,
        image_url: img.image_url,
        extracted_text: img.extracted_text,
        confidence: img.ocr_confidence,
      }))
    response.combined_text = upload.combined_text
    response.confidence = upload.overall_confidence
    response.processing_time_ms = upload.processing_time_ms
  } else if (upload.processing_status === 'processing') {
    // Show partial progress
    const completedPages = upload.diary_images.filter(
      (img: any) => img.processing_status === 'completed'
    ).length
    response.progress = {
      completed: completedPages,
      total: upload.page_count,
      percentage: Math.round((completedPages / upload.page_count) * 100),
    }
  } else if (upload.processing_status === 'failed') {
    response.error = 'OCR processing failed'
  }

  return c.json(response)
})

/**
 * Create a story from OCR-extracted diary content
 *
 * Uses AI to generate title and summary from extracted text
 */
app.post('/api/diary/:uploadId/create-story', authMiddleware, profileMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const profile = c.get('profile')
  const uploadId = c.req.param('uploadId')

  const body = await c.req.json()
  const customTitle = body.title as string | undefined
  const customText = body.combined_text as string | undefined

  // 1. Get upload record
  const { data: upload, error } = await supabase
    .from('diary_uploads')
    .select('*')
    .eq('id', uploadId)
    .eq('user_id', profile.id)
    .single()

  if (error || !upload) {
    return c.json({ error: 'Upload not found' }, 404)
  }

  if (upload.processing_status !== 'completed') {
    return c.json({ error: 'OCR processing not complete' }, 400)
  }

  const textToUse = customText || upload.combined_text

  if (!textToUse) {
    return c.json({ error: 'No text available to create story' }, 400)
  }

  // 2. Generate title and summary using AI (simplified - could use OpenAI)
  const title = customTitle || generateTitleFromText(textToUse)
  const summary = generateSummaryFromText(textToUse)

  // 3. Create story directly with prompt_text
  const { data: story, error: storyError } = await supabase
    .from('stories')
    .insert({
      family_id: profile.family_id,
      title,
      summary_text: summary,
      prompt_text: `Diary entry: ${title}`,
      prompt_category: 'diary',
      prompt_is_custom: true,
      is_completed: true,
      voice_count: 0,
    })
    .select()
    .single()

  if (storyError) {
    return c.json({ error: storyError.message }, 500)
  }

  // 4. Link upload to story
  await supabase
    .from('diary_uploads')
    .update({ story_id: story.id })
    .eq('id', uploadId)

  // 5. Create a text response with the extracted content
  await supabase
    .from('responses')
    .insert({
      story_id: story.id,
      user_id: profile.id,
      source: 'diary_ocr',
      transcription_text: textToUse,
      processing_status: 'completed',
    })

  return c.json({
    story_id: story.id,
    title,
    summary,
    extracted_text: textToUse,
  }, 201)
})

/**
 * Get all diary uploads for the current family
 */
app.get('/api/diary', authMiddleware, profileMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const profile = c.get('profile')

  const { data, error } = await supabase
    .from('diary_uploads')
    .select('id, source, title, processing_status, page_count, created_at, story_id')
    .eq('family_id', profile.family_id)
    .order('created_at', { ascending: false })
    .limit(50)

  if (error) {
    return c.json({ error: error.message }, 500)
  }

  return c.json(data)
})

/**
 * Delete a diary upload
 */
app.delete('/api/diary/:uploadId', authMiddleware, profileMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const profile = c.get('profile')
  const uploadId = c.req.param('uploadId')

  // Verify ownership
  const { data: upload } = await supabase
    .from('diary_uploads')
    .select('id, user_id')
    .eq('id', uploadId)
    .eq('user_id', profile.id)
    .single()

  if (!upload) {
    return c.json({ error: 'Upload not found or access denied' }, 404)
  }

  // Delete (cascade will handle diary_images)
  const { error } = await supabase
    .from('diary_uploads')
    .delete()
    .eq('id', uploadId)

  if (error) {
    return c.json({ error: error.message }, 500)
  }

  return c.json({ success: true })
})

// MARK: - Helper Functions

function generateTitleFromText(text: string): string {
  // Simple title generation - extract first meaningful sentence
  const sentences = text.split(/[.!?]/).filter(s => s.trim().length > 10)
  if (sentences.length > 0) {
    const firstSentence = sentences[0].trim()
    if (firstSentence.length > 60) {
      return firstSentence.substring(0, 57) + '...'
    }
    return firstSentence
  }
  return 'Diary Entry'
}

function generateSummaryFromText(text: string): string {
  // Simple summary - first 200 chars
  const cleaned = text.replace(/\s+/g, ' ').trim()
  if (cleaned.length > 200) {
    return cleaned.substring(0, 197) + '...'
  }
  return cleaned
}

export default app
