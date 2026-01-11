import { Hono } from 'hono'
import { authMiddleware, profileMiddleware } from '../middleware/auth'

const app = new Hono()

// ============================================================================
// EXPORT ENDPOINTS - Multi-format export for value extraction
// ============================================================================

/**
 * POST /api/stories/:id/export/pdf
 * Export a single story as PDF with images and formatted text
 *
 * Body: {
 *   includeImages: boolean
 *   includeTranscript: boolean
 *   includeMetadata: boolean
 *   watermarkText?: string
 * }
 */
app.post('/api/stories/:id/export/pdf', authMiddleware, profileMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const profile = c.get('profile')
  const storyId = c.req.param('id')
  const body = await c.req.json()

  // Verify story belongs to user's family
  const { data: story, error } = await supabase
    .from('stories')
    .select(`
      *,
      story_panels(image_url, caption, order_index),
      responses(transcription_text, profiles(full_name))
    `)
    .eq('id', storyId)
    .eq('family_id', profile.family_id)
    .single()

  if (error || !story) {
    return c.json({ error: 'Story not found' }, 404)
  }

  // TODO: Generate PDF using a library like PDFKit or jsPDF
  // For now, return a placeholder URL
  const pdfUrl = `https://storage.googleapis.com/${story.id}.pdf`

  // Track export
  await supabase.from('exports').insert({
    user_id: profile.id,
    story_id: storyId,
    format: 'pdf',
    options: body,
    status: 'completed',
    file_url: pdfUrl
  })

  return c.json({
    downloadUrl: pdfUrl,
    filename: `${story.title || 'story'}.pdf`,
    mimeType: 'application/pdf'
  })
})

/**
 * POST /api/stories/:id/export/audio
 * Export a story as audio file (MP3 or M4A)
 *
 * Body: {
 *   format: 'mp3' | 'm4a'
 *   includeMusic: boolean
 *   musicStyle: 'warm' | 'upbeat' | 'nostalgic'
 * }
 */
app.post('/api/stories/:id/export/audio', authMiddleware, profileMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const profile = c.get('profile')
  const storyId = c.req.param('id')
  const body = await c.req.json()

  const { data: story, error } = await supabase
    .from('stories')
    .select('*')
    .eq('id', storyId)
    .eq('family_id', profile.family_id)
    .single()

  if (error || !story) {
    return c.json({ error: 'Story not found' }, 404)
  }

  // If podcast already exists, return that
  if (story.podcast_url && story.podcast_status === 'ready') {
    const format = body.format || 'mp3'
    return c.json({
      downloadUrl: story.podcast_url,
      filename: `${story.title || 'story'}.${format}`,
      mimeType: format === 'mp3' ? 'audio/mpeg' : 'audio/mp4'
    })
  }

  // Otherwise, trigger podcast generation
  // TODO: Trigger background job for podcast generation
  return c.json({
    message: 'Podcast generation started',
    status: 'processing'
  }, 202)
})

/**
 * POST /api/stories/:id/export/video
 * Export a story as video slideshow (MP4)
 *
 * Body: {
 *   quality: '720p' | '1080p' | '4k'
 *   duration: number (target duration in seconds)
 *   transition: 'fade' | 'slide' | 'none'
 * }
 */
app.post('/api/stories/:id/export/video', authMiddleware, profileMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const profile = c.get('profile')
  const storyId = c.req.param('id')
  const body = await c.req.json()

  const { data: story, error } = await supabase
    .from('stories')
    .select(`
      *,
      story_panels(image_url, caption, order_index)
    `)
    .eq('id', storyId)
    .eq('family_id', profile.family_id)
    .single()

  if (error || !story) {
    return c.json({ error: 'Story not found' }, 404)
  }

  // TODO: Generate video slideshow
  // Using FFmpeg or similar tool
  // 1. Combine images + audio
  // 2. Add transitions
  // 3. Export as MP4

  return c.json({
    message: 'Video export started',
    status: 'processing'
  }, 202)
})

/**
 * POST /api/stories/:id/export/json
 * Export complete story data as JSON (backup)
 *
 * Body: {
 *   includeResponses: boolean
 *   includeMetadata: boolean
 * }
 */
app.post('/api/stories/:id/export/json', authMiddleware, profileMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const profile = c.get('profile')
  const storyId = c.req.param('id')
  const body = await c.req.json()

  const { data: story, error } = await supabase
    .from('stories')
    .select(`
      *,
      responses(*),
      story_panels(*)
    `)
    .eq('id', storyId)
    .eq('family_id', profile.family_id)
    .single()

  if (error || !story) {
    return c.json({ error: 'Story not found' }, 404)
  }

  // Create JSON backup
  const jsonData = JSON.stringify(story, null, 2)

  // TODO: Upload to R2 and return URL
  return c.json({
    data: story,
    filename: `${story.title || 'story'}.json`,
    mimeType: 'application/json'
  })
})

/**
 * POST /api/stories/:id/export/epub
 * Export a story as EPUB (e-book format)
 *
 * Body: {
 *   includeImages: boolean
 *   tableOfContents: boolean
 * }
 */
app.post('/api/stories/:id/export/epub', authMiddleware, profileMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const profile = c.get('profile')
  const storyId = c.req.param('id')
  const body = await c.req.json()

  const { data: story, error } = await supabase
    .from('stories')
    .select('*')
    .eq('id', storyId)
    .eq('family_id', profile.family_id)
    .single()

  if (error || !story) {
    return c.json({ error: 'Story not found' }, 404)
  }

  // TODO: Generate EPUB using a library like epub-gen
  return c.json({
    message: 'EPUB generation started',
    status: 'processing'
  }, 202)
})

/**
 * POST /api/collections/:id/export
 * Export an entire collection as a bundled format
 *
 * Body: {
 *   format: 'pdf' | 'audio' | 'video' | 'epub'
 *   options: export-specific options
 * }
 */
app.post('/api/collections/:id/export', authMiddleware, profileMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const profile = c.get('profile')
  const collectionId = c.req.param('id')
  const body = await c.req.json()

  const { data: collection, error } = await supabase
    .from('collections')
    .select(`
      *,
      collection_stories(
        order_index,
        stories(*)
      )
    `)
    .eq('id', collectionId)
    .eq('family_id', profile.family_id)
    .single()

  if (error || !collection) {
    return c.json({ error: 'Collection not found' }, 404)
  }

  // Route to appropriate export handler
  switch (body.format) {
    case 'pdf':
      // TODO: Generate multi-story PDF
      return c.json({ message: 'Collection PDF export started', status: 'processing' }, 202)
    case 'audio':
      // TODO: Generate podcast with multiple episodes
      return c.json({ message: 'Collection audio export started', status: 'processing' }, 202)
    case 'epub':
      // TODO: Generate anthology as EPUB
      return c.json({ message: 'Collection EPUB export started', status: 'processing' }, 202)
    default:
      return c.json({ error: 'Unsupported format' }, 400)
  }
})

/**
 * GET /api/exports
 * List all exports for the current user
 */
app.get('/api/exports', authMiddleware, profileMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const profile = c.get('profile')

  const { data, error } = await supabase
    .from('exports')
    .select('*')
    .eq('user_id', profile.id)
    .order('created_at', { ascending: false })

  if (error) {
    return c.json({ error: error.message }, 500)
  }

  return c.json(data)
})

export default app
