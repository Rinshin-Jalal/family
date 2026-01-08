import { Hono } from 'hono'
import { authMiddleware, profileMiddleware } from '../middleware/auth'

const app = new Hono()

// Generate a unique 8-character token
function generateToken(): string {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789'
  let token = ''
  for (let i = 0; i < 8; i++) {
    token += chars.charAt(Math.floor(Math.random() * chars.length))
  }
  return token
}

/**
 * POST /api/stories/:id/share-link
 * Create a public share link for a story
 *
 * Body: {
 *   permissions: { view: true, download: false, comment: false }
 *   expiresAt: string | null (ISO date)
 *   showWatermark: boolean
 *   watermarkText: string | null
 * }
 */
app.post('/api/stories/:id/share-link', authMiddleware, profileMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const profile = c.get('profile')
  const storyId = c.req.param('id')
  const body = await c.req.json()

  // Verify the story belongs to the user's family
  const { data: story, error: storyError } = await supabase
    .from('stories')
    .select('family_id')
    .eq('id', storyId)
    .single()

  if (storyError || !story) {
    return c.json({ error: 'Story not found' }, 404)
  }

  if (story.family_id !== profile.family_id) {
    return c.json({ error: 'Unauthorized' }, 403)
  }

  // Generate unique token
  let token = generateToken()
  let tokenExists = true

  // Ensure token uniqueness
  while (tokenExists) {
    const { data: existing } = await supabase
      .from('share_links')
      .select('token')
      .eq('token', token)
      .single()

    if (!existing) {
      tokenExists = false
    } else {
      token = generateToken()
    }
  }

  // Create share link
  const { data: shareLink, error: createError } = await supabase
    .from('share_links')
    .insert({
      created_by: profile.id,
      target_type: 'story',
      target_id: storyId,
      token,
      permissions: body.permissions || { view: true, download: false, comment: false },
      show_watermark: body.showWatermark ?? true,
      watermark_text: body.watermarkText || null,
      expires_at: body.expiresAt || null,
      is_active: true,
      view_count: 0,
    })
    .select()
    .single()

  if (createError) {
    return c.json({ error: createError.message }, 500)
  }

  return c.json({
    shareLink,
    publicUrl: `${c.req.url.split('/api/')[0]}/s/${token}`
  }, 201)
})

/**
 * POST /api/collections/:id/share-link
 * Create a public share link for a collection
 *
 * Body: {
 *   permissions: { view: true, download: false, comment: false }
 *   expiresAt: string | null (ISO date)
 *   showWatermark: boolean
 *   watermarkText: string | null
 * }
 */
app.post('/api/collections/:id/share-link', authMiddleware, profileMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const profile = c.get('profile')
  const collectionId = c.req.param('id')
  const body = await c.req.json()

  // Verify the collection belongs to the user's family
  const { data: collection, error: collectionError } = await supabase
    .from('collections')
    .select('family_id')
    .eq('id', collectionId)
    .single()

  if (collectionError || !collection) {
    return c.json({ error: 'Collection not found' }, 404)
  }

  if (collection.family_id !== profile.family_id) {
    return c.json({ error: 'Unauthorized' }, 403)
  }

  // Generate unique token
  let token = generateToken()
  let tokenExists = true

  while (tokenExists) {
    const { data: existing } = await supabase
      .from('share_links')
      .select('token')
      .eq('token', token)
      .single()

    if (!existing) {
      tokenExists = false
    } else {
      token = generateToken()
    }
  }

  // Create share link
  const { data: shareLink, error: createError } = await supabase
    .from('share_links')
    .insert({
      created_by: profile.id,
      target_type: 'collection',
      target_id: collectionId,
      token,
      permissions: body.permissions || { view: true, download: false, comment: false },
      show_watermark: body.showWatermark ?? true,
      watermark_text: body.watermarkText || null,
      expires_at: body.expiresAt || null,
      is_active: true,
      view_count: 0,
    })
    .select()
    .single()

  if (createError) {
    return c.json({ error: createError.message }, 500)
  }

  return c.json({
    shareLink,
    publicUrl: `${c.req.url.split('/api/')[0]}/s/${token}`
  }, 201)
})

/**
 * GET /api/public/s/:token
 * Public endpoint to access shared content (no auth required)
 *
 * Returns the story or collection with share link metadata
 * Includes watermark info if show_watermark is true
 */
app.get('/api/public/s/:token', async (c) => {
  const supabase = c.get('supabase')
  const token = c.req.param('token')

  // Get share link
  const { data: shareLink, error: linkError } = await supabase
    .from('share_links')
    .select('*')
    .eq('token', token)
    .eq('is_active', true)
    .single()

  if (linkError || !shareLink) {
    return c.json({ error: 'Share link not found or inactive' }, 404)
  }

  // Check expiration
  if (shareLink.expires_at && new Date(shareLink.expires_at) < new Date()) {
    return c.json({ error: 'Share link has expired' }, 410)
  }

  // Increment view count
  await supabase
    .from('share_links')
    .update({
      view_count: (shareLink.view_count || 0) + 1,
      last_accessed_at: new Date().toISOString()
    })
    .eq('id', shareLink.id)

  // Fetch content based on target type
  if (shareLink.target_type === 'story') {
    const { data: story, error: storyError } = await supabase
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
        ),
        story_panels(
          id,
          image_url,
          caption,
          order_index
        )
      `)
      .eq('id', shareLink.target_id)
      .single()

    if (storyError || !story) {
      return c.json({ error: 'Story not found' }, 404)
    }

    return c.json({
      content: story,
      shareLink: {
        showWatermark: shareLink.show_watermark,
        watermarkText: shareLink.watermark_text,
        permissions: shareLink.permissions,
      }
    })
  }

  if (shareLink.target_type === 'collection') {
    const { data: collection, error: collectionError } = await supabase
      .from('collections')
      .select(`
        *,
        collection_stories(
          order_index,
          notes,
          stories(
            *,
            prompt:prompts(text, category),
            story_panels(
              id,
              image_url,
              caption,
              order_index
            )
          )
        )
      `)
      .eq('id', shareLink.target_id)
      .single()

    if (collectionError || !collection) {
      return c.json({ error: 'Collection not found' }, 404)
    }

    return c.json({
      content: collection,
      shareLink: {
        showWatermark: shareLink.show_watermark,
        watermarkText: shareLink.watermark_text,
        permissions: shareLink.permissions,
      }
    })
  }

  return c.json({ error: 'Invalid target type' }, 400)
})

/**
 * GET /api/share-links
 * Get all share links created by the current user
 */
app.get('/api/share-links', authMiddleware, profileMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const profile = c.get('profile')

  const { data: shareLinks, error } = await supabase
    .from('share_links')
    .select(`
      *,
      story:stories(id, title, cover_image_url)
      collection:collections(id, title, cover_image_url)
    `)
    .eq('created_by', profile.id)
    .order('created_at', { ascending: false })

  if (error) {
    return c.json({ error: error.message }, 500)
  }

  return c.json(shareLinks)
})

/**
 * DELETE /api/share-links/:id
 * Deactivate a share link
 */
app.delete('/api/share-links/:id', authMiddleware, profileMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const profile = c.get('profile')
  const linkId = c.req.param('id')

  // Verify ownership
  const { data: shareLink, error: linkError } = await supabase
    .from('share_links')
    .select('created_by')
    .eq('id', linkId)
    .single()

  if (linkError || !shareLink) {
    return c.json({ error: 'Share link not found' }, 404)
  }

  if (shareLink.created_by !== profile.id) {
    return c.json({ error: 'Unauthorized' }, 403)
  }

  // Deactivate instead of deleting
  const { error: updateError } = await supabase
    .from('share_links')
    .update({ is_active: false })
    .eq('id', linkId)

  if (updateError) {
    return c.json({ error: updateError.message }, 500)
  }

  return c.json({ success: true })
})

/**
 * PATCH /api/share-links/:id
 * Update share link settings (permissions, expiration, watermark)
 */
app.patch('/api/share-links/:id', authMiddleware, profileMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const profile = c.get('profile')
  const linkId = c.req.param('id')
  const body = await c.req.json()

  // Verify ownership
  const { data: shareLink, error: linkError } = await supabase
    .from('share_links')
    .select('created_by')
    .eq('id', linkId)
    .single()

  if (linkError || !shareLink) {
    return c.json({ error: 'Share link not found' }, 404)
  }

  if (shareLink.created_by !== profile.id) {
    return c.json({ error: 'Unauthorized' }, 403)
  }

  // Build update object with only provided fields
  const updates: any = {}
  if (body.permissions !== undefined) updates.permissions = body.permissions
  if (body.expiresAt !== undefined) updates.expires_at = body.expiresAt
  if (body.showWatermark !== undefined) updates.show_watermark = body.showWatermark
  if (body.watermarkText !== undefined) updates.watermark_text = body.watermarkText
  if (body.isActive !== undefined) updates.is_active = body.isActive

  const { error: updateError } = await supabase
    .from('share_links')
    .update(updates)
    .eq('id', linkId)
    .select()
    .single()

  if (updateError) {
    return c.json({ error: updateError.message }, 500)
  }

  return c.json({ success: true })
})

export default app
