import { Hono } from 'hono'
import { authMiddleware } from '../middleware/auth'

const app = new Hono<{ Bindings: any; Variables: any }>()

/**
 * GET /api/trivia
 * Get available quizzes for user's family
 */
app.get('/api/trivia', authMiddleware, async (c) => {
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

  const { data: quizzes, error } = await supabase
    .from('trivia_quizzes')
    .select('*')
    .eq('family_id', profile.family_id)
    .eq('is_active', true)
    .order('created_at', { ascending: false })

  if (error) {
    return c.json({ error: 'Failed to fetch quizzes' }, 500)
  }

  return c.json({ quizzes: quizzes || [], count: quizzes?.length || 0 })
})

/**
 * GET /api/trivia/:id
 * Get quiz with questions
 */
app.get('/api/trivia/:id', authMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const quizId = c.req.param('id')

  const { data: quiz, error } = await supabase
    .from('trivia_quizzes')
    .select('*')
    .eq('id', quizId)
    .single()

  if (error || !quiz) {
    return c.json({ error: 'Quiz not found' }, 404)
  }

  const { data: questions, error: qError } = await supabase
    .from('trivia_questions')
    .select('id, question_text, question_type, option_a, option_b, option_c, option_d, display_order')
    .eq('quiz_id', quizId)
    .order('display_order')

  if (qError) {
    return c.json({ error: 'Failed to fetch questions' }, 500)
  }

  return c.json({
    quiz,
    questions: questions || [],
    questionCount: questions?.length || 0,
  })
})

/**
 * POST /api/trivia
 * Create a new quiz (or AI-generate from story)
 */
app.post('/api/trivia', authMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const body = await c.req.json()
  const { title, description, story_id, question_count, difficulty } = body
  const userId = c.get('userId')

  const { data: profile } = await supabase
    .from('profiles')
    .select('id, family_id')
    .eq('auth_user_id', userId)
    .single()

  if (!profile) {
    return c.json({ error: 'Profile not found' }, 404)
  }

  const { data: quiz, error } = await supabase
    .from('trivia_quizzes')
    .insert({
      title: title || 'Family Trivia Quiz',
      description,
      story_id,
      question_count: question_count || 5,
      difficulty: difficulty || 'medium',
      created_by: profile.id,
      family_id: profile.family_id,
    })
    .select()
    .single()

  if (error) {
    return c.json({ error: 'Failed to create quiz' }, 500)
  }

  return c.json({ quiz }, 201)
})

/**
 * POST /api/trivia/generate-from-story
 * Generate trivia questions from a story using AI
 */
app.post('/api/trivia/generate-from-story', authMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const body = await c.req.json()
  const { story_id, question_count } = body
  const userId = c.get('userId')

  if (!story_id) {
    return c.json({ error: 'Story ID required' }, 400)
  }

  const { data: story } = await supabase
    .from('stories')
    .select('id, title, family_id')
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
    .select('transcription_text, profiles(full_name, role)')
    .eq('story_id', story_id)
    .limit(10)

  const storyContent = responses?.map(r => 
    `${r.profiles?.full_name || 'Speaker'}: ${r.transcription_text}`
  ).join('\n\n') || ''

  return c.json({
    status: 'ready',
    storyId: story_id,
    questionCount: question_count || 5,
    message: 'AI trivia generation would be triggered here',
    storyContent: storyContent.substring(0, 500),
  })
})

/**
 * POST /api/trivia/session
 * Start a new trivia session
 */
app.post('/api/trivia/session', authMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const body = await c.req.json()
  const { quiz_id, player_name } = body
  const userId = c.get('userId')

  if (!quiz_id || !player_name) {
    return c.json({ error: 'Quiz ID and player name required' }, 400)
  }

  const { data: profile } = await supabase
    .from('profiles')
    .select('id')
    .eq('auth_user_id', userId)
    .single()

  const { data: session, error } = await supabase
    .from('trivia_sessions')
    .insert({
      quiz_id,
      player_id: profile?.id,
      player_name,
      status: 'in_progress',
    })
    .select()
    .single()

  if (error) {
    return c.json({ error: 'Failed to create session' }, 500)
  }

  return c.json({ session }, 201)
})

/**
 * POST /api/trivia/session/:sessionId/answer
 * Submit an answer for a question
 */
app.post('/api/trivia/session/:sessionId/answer', authMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const sessionId = c.req.param('sessionId')
  const body = await c.req.json()
  const { question_id, answer, time_to_answer } = body

  if (!question_id || !answer) {
    return c.json({ error: 'Question ID and answer required' }, 400)
  }

  const { data: session, error: sessionError } = await supabase
    .from('trivia_sessions')
    .select('*')
    .eq('id', sessionId)
    .single()

  if (sessionError || !session) {
    return c.json({ error: 'Session not found' }, 404)
  }

  if (session.status !== 'in_progress') {
    return c.json({ error: 'Session is not active' }, 400)
  }

  const { data: result } = await supabase
    .rpc('check_trivia_answer', {
      p_question_id: question_id,
      p_answer: answer,
    })

  const isCorrect = result?.is_correct || false

  const { data: answerRecord, error: answerError } = await supabase
    .from('trivia_answers')
    .insert({
      session_id: sessionId,
      question_id,
      selected_answer: answer,
      is_correct: isCorrect,
      time_to_answer_seconds: time_to_answer || 0,
    })
    .select()
    .single()

  if (answerError) {
    return c.json({ error: 'Failed to record answer' }, 500)
  }

  return c.json({
    answer: answerRecord,
    isCorrect,
    correctAnswer: result?.correct_answer,
    explanation: result?.explanation,
  })
})

/**
 * POST /api/trivia/session/:sessionId/complete
 * Complete a trivia session and calculate score
 */
app.post('/api/trivia/session/:sessionId/complete', authMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const sessionId = c.req.param('sessionId')

  const { data: session } = await supabase
    .from('trivia_sessions')
    .select('*')
    .eq('id', sessionId)
    .single()

  if (!session) {
    return c.json({ error: 'Session not found' }, 404)
  }

  const { data: answers } = await supabase
    .from('trivia_answers')
    .select('*')
    .eq('session_id', sessionId)

  const correctCount = answers?.filter(a => a.is_correct).count || 0
  const totalTime = answers?.reduce((sum, a) => sum + (a.time_to_answer_seconds || 0), 0) || 0
  const totalQuestions = answers?.count || 0

  const { data: quiz } = await supabase
    .from('trivia_quizzes')
    .select('time_limit_seconds')
    .eq('id', session.quiz_id)
    .single()

  const maxTime = (quiz?.time_limit_seconds || 30) * totalQuestions
  const score = await supabase.rpc('calculate_trivia_score', {
    p_correct_count: correctCount,
    p_time_spent: totalTime,
    p_max_time: maxTime,
  })

  const { error } = await supabase
    .from('trivia_sessions')
    .update({
      score: score || 0,
      total_questions: totalQuestions,
      correct_answers: correctCount,
      time_spent_seconds: totalTime,
      status: 'completed',
      completed_at: new Date().toISOString(),
    })
    .eq('id', sessionId)

  if (error) {
    return c.json({ error: 'Failed to complete session' }, 500)
  }

  return c.json({
    success: true,
    score: score || 0,
    correctAnswers: correctCount,
    totalQuestions,
    timeSpent: totalTime,
  })
})

/**
 * GET /api/trivia/session/:sessionId/results
 * Get session results with answers
 */
app.get('/api/trivia/session/:sessionId/results', authMiddleware, async (c) => {
  const supabase = c.get('supabase')
  const sessionId = c.req.param('sessionId')

  const { data: session, error } = await supabase
    .from('trivia_sessions')
    .select('*')
    .eq('id', sessionId)
    .single()

  if (error || !session) {
    return c.json({ error: 'Session not found' }, 404)
  }

  const { data: answers } = await supabase
    .from('trivia_answers')
    .select('*')
    .eq('session_id', sessionId)

  return c.json({
    session,
    answers: answers || [],
    correctCount: answers?.filter(a => a.is_correct).count || 0,
  })
})

// LEADERBOARD REMOVED: Leaderboards promoted toxic competition in family dynamics.
// The app should focus on value extraction (learning family stories) not social comparison.

export default app
