-- =========================================================================
-- STORYRD - TRIVIA GAME
-- Adds: trivia_quizzes, trivia_questions, trivia_answers, trivia_sessions
-- =========================================================================

-- 1. TRIVIA QUIZZES - Generated quiz sessions
-- =========================================================================
CREATE TABLE trivia_quizzes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Quiz content
    title TEXT NOT NULL,
    description TEXT,
    story_id UUID REFERENCES stories(id) ON DELETE SET NULL,
    
    -- Quiz settings
    question_count INT DEFAULT 5,
    time_limit_seconds INT DEFAULT 30,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    difficulty VARCHAR(20) DEFAULT 'medium',  -- 'easy', 'medium', 'hard'
    
    -- Metadata
    created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    family_id UUID REFERENCES families(id) ON DELETE CASCADE NOT NULL,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. TRIVIA QUESTIONS - Individual questions
-- =========================================================================
CREATE TABLE trivia_questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    quiz_id UUID REFERENCES trivia_quizzes(id) ON DELETE CASCADE NOT NULL,
    
    -- Question content
    question_text TEXT NOT NULL,
    question_type VARCHAR(20) DEFAULT 'multiple_choice',  -- 'multiple_choice', 'true_false', 'open_ended'
    
    -- Options (for multiple choice)
    option_a TEXT,
    option_b TEXT,
    option_c TEXT,
    option_d TEXT,
    
    -- Correct answer
    correct_answer VARCHAR(10) NOT NULL,  -- 'A', 'B', 'C', 'D', 'true', 'false'
    explanation TEXT,
    
    -- Source attribution
    source_story_id UUID REFERENCES stories(id) ON DELETE SET NULL,
    speaker_name VARCHAR(100),
    
    -- Sort order
    display_order INT DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. TRIVIA SESSIONS - Individual game sessions
-- =========================================================================
CREATE TABLE trivia_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    quiz_id UUID REFERENCES trivia_quizzes(id) ON DELETE CASCADE NOT NULL,
    
    -- Player info
    player_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    player_name VARCHAR(100) NOT NULL,
    
    -- Session results
    score INT DEFAULT 0,
    total_questions INT DEFAULT 0,
    correct_answers INT DEFAULT 0,
    time_spent_seconds INT DEFAULT 0,
    
    -- Status
    status VARCHAR(20) DEFAULT 'in_progress',  -- 'in_progress', 'completed', 'abandoned'
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. TRIVIA ANSWERS - Player answers
-- =========================================================================
CREATE TABLE trivia_answers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID REFERENCES trivia_sessions(id) ON DELETE CASCADE NOT NULL,
    question_id UUID REFERENCES trivia_questions(id) ON DELETE CASCADE NOT NULL,
    
    -- Answer
    selected_answer VARCHAR(10) NOT NULL,
    is_correct BOOLEAN NOT NULL,
    time_to_answer_seconds INT DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. ENABLE RLS
-- =========================================================================
ALTER TABLE trivia_quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE trivia_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE trivia_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE trivia_answers ENABLE ROW LEVEL SECURITY;

-- TRIVIA_QUIZZES
CREATE POLICY "Family can view quizzes" ON trivia_quizzes
    FOR SELECT USING (
        family_id IN (SELECT family_id FROM profiles WHERE auth_user_id = auth.uid())
    );

CREATE POLICY "Family can create quizzes" ON trivia_quizzes
    FOR INSERT WITH CHECK (
        family_id IN (SELECT family_id FROM profiles WHERE auth_user_id = auth.uid())
    );

-- TRIVIA_QUESTIONS
CREATE POLICY "View quiz questions" ON trivia_questions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM trivia_quizzes
            WHERE trivia_quizzes.id = trivia_questions.quiz_id
            AND trivia_quizzes.family_id IN (SELECT family_id FROM profiles WHERE auth_user_id = auth.uid())
        )
    );

-- TRIVIA_SESSIONS
CREATE POLICY "View own sessions" ON trivia_sessions
    FOR SELECT USING (
        player_id IN (SELECT id FROM profiles WHERE auth_user_id = auth.uid())
        OR player_name IN (SELECT full_name FROM profiles WHERE auth_user_id = auth.uid())
    );

CREATE POLICY "Create session" ON trivia_sessions
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Update own session" ON trivia_sessions
    FOR UPDATE USING (
        player_id IN (SELECT id FROM profiles WHERE auth_user_id = auth.uid())
    );

-- TRIVIA_ANSWERS
CREATE POLICY "View session answers" ON trivia_answers
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM trivia_sessions
            WHERE trivia_sessions.id = trivia_answers.session_id
            AND (trivia_sessions.player_id IN (SELECT id FROM profiles WHERE auth_user_id = auth.uid())
                 OR EXISTS (SELECT 1 FROM profiles WHERE auth_user_id = auth.uid() AND full_name = trivia_sessions.player_name))
        )
    );

CREATE POLICY "Record answers" ON trivia_answers
    FOR INSERT WITH CHECK (true);

-- 6. INDEXES
-- =========================================================================
CREATE INDEX idx_quizzes_family ON trivia_quizzes(family_id);
CREATE INDEX idx_quizzes_active ON trivia_quizzes(is_active);

CREATE INDEX idx_questions_quiz ON trivia_questions(quiz_id, display_order);

CREATE INDEX idx_sessions_player ON trivia_sessions(player_id, created_at);
CREATE INDEX idx_sessions_quiz ON trivia_sessions(quiz_id);

CREATE INDEX idx_answers_session ON trivia_answers(session_id);

-- 7. HELPER FUNCTIONS
-- =========================================================================

-- FUNCTION: Generate trivia questions from story
CREATE OR REPLACE FUNCTION generate_trivia_from_story(
    p_story_id UUID,
    p_question_count INT DEFAULT 5
) RETURNS JSONB AS $$
DECLARE
    v_quiz_id UUID;
    v_result JSONB;
BEGIN
    -- This is a placeholder - actual AI generation happens in app layer
    -- The app layer uses AI to extract trivia-worthy facts from story transcriptions
    
    v_result := jsonb_build_object(
        'status', 'ready',
        'story_id', p_story_id,
        'question_count', p_question_count,
        'message', 'Trivia generation would be triggered via API call'
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- FUNCTION: Get leaderboard for a quiz
CREATE OR REPLACE FUNCTION get_quiz_leaderboard(
    p_quiz_id UUID,
    p_limit INT DEFAULT 10
) RETURNS TABLE (
    rank INT,
    player_name VARCHAR(100),
    score INT,
    correct_answers INT,
    time_spent INT,
    completed_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ROW_NUMBER() OVER (ORDER BY ts.score DESC, ts.time_spent_seconds ASC) as rank,
        ts.player_name,
        ts.score,
        ts.correct_answers,
        ts.time_spent_seconds,
        ts.completed_at
    FROM trivia_sessions ts
    WHERE ts.quiz_id = p_quiz_id
    AND ts.status = 'completed'
    ORDER BY ts.score DESC, ts.time_spent_seconds ASC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- FUNCTION: Calculate score
CREATE OR REPLACE FUNCTION calculate_trivia_score(
    p_correct_count INT,
    p_time_spent INT,
    p_max_time INT DEFAULT 300
) RETURNS INT AS $$
DECLARE
    v_base_points INT := 100;
    v_time_bonus INT;
BEGIN
    -- Base points per correct answer
    v_base_points := p_correct_count * 100;
    
    -- Time bonus: faster = more points (max 50% bonus)
    v_time_bonus := LEAST(50, FLOOR((1.0 - (p_time_spent::FLOAT / p_max_time::FLOAT)) * 50)::INT);
    
    RETURN v_base_points + v_time_bonus;
END;
$$ LANGUAGE plpgsql;

-- FUNCTION: Get quiz with questions
CREATE OR REPLACE FUNCTION get_quiz_with_questions(p_quiz_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_quiz JSONB;
    v_questions JSONB;
BEGIN
    SELECT json_build_object(
        'id', q.id,
        'title', q.title,
        'description', q.description,
        'question_count', q.question_count,
        'time_limit_seconds', q.time_limit_seconds,
        'difficulty', q.difficulty
    ) INTO v_quiz
    FROM trivia_quizzes q WHERE q.id = p_quiz_id;
    
    SELECT json_agg(
        json_build_object(
            'id', tq.id,
            'question_text', tq.question_text,
            'question_type', tq.question_type,
            'options', json_build_object(
                'a', tq.option_a,
                'b', tq.option_b,
                'c', tq.option_c,
                'd', tq.option_d
            )
        ) ORDER BY tq.display_order
    ) INTO v_questions
    FROM trivia_questions tq
    WHERE tq.quiz_id = p_quiz_id;
    
    RETURN jsonb_build_object(
        'quiz', v_quiz,
        'questions', COALESCE(v_questions, '[]'::jsonb)
    );
END;
$$ LANGUAGE plpgsql;

-- FUNCTION: Check answer and return result
CREATE OR REPLACE FUNCTION check_trivia_answer(
    p_question_id UUID,
    p_answer VARCHAR(10)
) RETURNS JSONB AS $$
DECLARE
    v_question RECORD;
    v_is_correct BOOLEAN;
BEGIN
    SELECT * INTO v_question FROM trivia_questions WHERE id = p_question_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('error', 'Question not found');
    END IF;
    
    v_is_correct := UPPER(p_answer) = UPPER(v_question.correct_answer);
    
    RETURN jsonb_build_object(
        'is_correct', v_is_correct,
        'correct_answer', v_question.correct_answer,
        'explanation', v_question.explanation
    );
END;
$$ LANGUAGE plpgsql;

