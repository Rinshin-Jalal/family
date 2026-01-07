import { Hono } from 'hono'
import { authMiddleware } from '../middleware/auth'

const app = new Hono<{ Bindings: any; Variables: any }>()

/**
 * GET /api/polls
 * Get active polls for the user's family
 */
app.get('/api/polls', authMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const userId = c.get('userId')

  const { data: profile } = await supabase
    .from('profiles')
    .select('id, family_id')
    .eq('auth_user_id', userId)
    .single()

  if (!profile) {
    return c.json({ error: 'Profile not found' }, 404)
  }

  const { data: polls, error } = await supabase
    .rpc('get_active_polls', { p_family_id: profile.family_id })

  if (error) {
    return c.json({ error: 'Failed to fetch polls' }, 500)
  }

  return c.json({ polls: polls || [], count: polls?.length || 0 })
})

/**
 * GET /api/polls/:id
 * Get a specific poll with options and results
 */
app.get('/api/polls/:id', authMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const pollId = c.req.param('id')
  const userId = c.get('userId')

  const { data: poll, error } = await supabase
    .from('polls')
    .select('*')
    .eq('id', pollId)
    .single()

  if (error || !poll) {
    return c.json({ error: 'Poll not found' }, 404)
  }

  const { data: options } = await supabase
    .from('poll_options')
    .select('*')
    .eq('poll_id', pollId)
    .order('display_order')

  const { data: userVote } = await supabase
    .rpc('get_user_vote', { 
      p_poll_id: pollId, 
      p_user_id: profile.id 
    })

  const { data: results } = await supabase
    .rpc('get_poll_results', { p_poll_id: pollId })

  return c.json({
    poll,
    options,
    userVote,
    results,
  })
})

/**
 * POST /api/polls
 * Create a new poll
 */
app.post('/api/polls', authMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const body = await c.req.json()
  const { question, description, poll_type, options, ends_at } = body
  const userId = c.get('userId')

  if (!question || !options?.length) {
    return c.json({ error: 'Question and options required' }, 400)
  }

  const { data: profile } = await supabase
    .from('profiles')
    .select('id, family_id')
    .eq('auth_user_id', userId)
    .single()

  if (!profile) {
    return c.json({ error: 'Profile not found' }, 404)
  }

  const { data: poll, error: pollError } = await supabase
    .from('polls')
    .insert({
      question,
      description,
      poll_type: poll_type || 'generational',
      ends_at: ends_at || new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString(),
      created_by: profile.id,
      family_id: profile.family_id,
    })
    .select()
    .single()

  if (pollError) {
    return c.json({ error: 'Failed to create poll' }, 500)
  }

  const optionsData = options.map((opt: string, idx: number) => ({
    poll_id: poll.id,
    option_text: opt,
    option_label: String.fromCharCode(65 + idx),
    display_order: idx,
  }))

  const { data: createdOptions, error: optionsError } = await supabase
    .from('poll_options')
    .insert(optionsData)
    .select()

  if (optionsError) {
    await supabase.from('polls').delete().eq('id', poll.id)
    return c.json({ error: 'Failed to create poll options' }, 500)
  }

  return c.json({
    poll,
    options: createdOptions,
  }, 201)
})

/**
 * POST /api/polls/:id/vote
 * Vote on a poll
 */
app.post('/api/polls/:id/vote', authMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const pollId = c.req.param('id')
  const body = await c.req.json()
  const { option_id, justification } = body
  const userId = c.get('userId')

  if (!option_id) {
    return c.json({ error: 'Option required' }, 400)
  }

  const { data: profile } = await supabase
    .from('profiles')
    .select('id, role')
    .eq('auth_user_id', userId)
    .single()

  if (!profile) {
    return c.json({ error: 'Profile not found' }, 404)
  }

  const { data: poll } = await supabase
    .from('polls')
    .select('id, is_active, ends_at')
    .eq('id', pollId)
    .single()

  if (!poll || !poll.is_active || new Date(poll.ends_at) < new Date()) {
    return c.json({ error: 'Poll is not active' }, 400)
  }

  const { data: existingVote } = await supabase
    .from('poll_votes')
    .select('id')
    .eq('poll_id', pollId)
    .eq('voter_id', profile.id)
    .single()

  if (existingVote) {
    return c.json({ error: 'Already voted on this poll' }, 400)
  }

  const { error: voteError } = await supabase
    .from('poll_votes')
    .insert({
      poll_id: pollId,
      option_id,
      voter_id: profile.id,
      justification,
      generation: profile.role,
    })

  if (voteError) {
    return c.json({ error: 'Failed to record vote' }, 500)
  }

  return c.json({ success: true, message: 'Vote recorded' })
})

/**
 * POST /api/polls/generate-from-story
 * Generate a poll from a story using AI
 */
app.post('/api/polls/generate-from-story', authMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const body = await c.req.json()
  const { story_id } = body
  const userId = c.get('userId')

  if (!story_id) {
    return c.json({ error: 'Story ID required' }, 400)
  }

  const { data: story } = await supabase
    .from('stories')
    .select('id, title, summary_text, family_id')
    .eq('id', story_id)
    .single()

  if (!story) {
    return c.json({ error: 'Story not found' }, 404)
  }

  const { data: profile } = await supabase
    .from('profiles')
    .select('id, family_id')
    .eq('auth_user_id', userId)
    .single()

  if (profile?.family_id !== story.family_id) {
    return c.json({ error: 'Unauthorized' }, 403)
  }

  const { data: responses } = await supabase
    .from('responses')
    .select('transcription_text')
    .eq('story_id', story_id)
    .limit(5)

  const combinedText = responses?.map(r => r.transcription_text).join(' ') || ''

  return c.json({
    status: 'ready',
    storyId: story_id,
    message: 'AI poll generation would be triggered here with story content',
    storyContent: combinedText.substring(0, 500),
  })
})

/**
 * GET /api/polls/:id/results
 * Get poll results
 */
app.get('/api/polls/:id/results', authMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const pollId = c.req.param('id')

  const { data: results, error } = await supabase
    .rpc('get_poll_results', { p_poll_id: pollId })

  if (error) {
    return c.json({ error: 'Failed to fetch results' }, 500)
  }

  return c.json({ results: results || [] })
})

/**
 * DELETE /api/polls/:id
 * Delete a poll (owner only)
 */
app.delete('/api/polls/:id', authMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const pollId = c.req.param('id')
  const userId = c.get('userId')

  const { data: profile } = await supabase
    .from('profiles')
    .select('id')
    .eq('auth_user_id', userId)
    .single()

  const { error } = await supabase
    .from('polls')
    .delete()
    .eq('id', pollId)
    .eq('created_by', profile?.id)

  if (error) {
    return c.json({ error: 'Failed to delete poll' }, 500)
  }

  return c.json({ success: true })
})

export default app
