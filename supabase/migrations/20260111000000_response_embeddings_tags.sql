-- =========================================================================
-- RESPONSE-LEVEL EMBEDDINGS & WISDOM TAGS MIGRATION
-- Shifts wisdom tagging and embeddings from story-level to response-level
-- =========================================================================

-- 1. ADD EMBEDDING COLUMN TO RESPONSES TABLE
-- =========================================================================
ALTER TABLE responses ADD COLUMN embedding vector(1024);

-- 2. CREATE RESPONSE_TAGS TABLE (similar to story_tags but for responses)
-- =========================================================================
CREATE TABLE response_tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    response_id UUID REFERENCES responses(id) ON DELETE CASCADE NOT NULL,
    
    -- Tag categories for wisdom search (same as story_tags)
    emotion_tags TEXT[] DEFAULT '{}',
    situation_tags TEXT[] DEFAULT '{}',
    lesson_tags TEXT[] DEFAULT '{}',
    guidance_tags TEXT[] DEFAULT '{}',
    
    -- Searchable question keywords
    question_keywords TEXT[] DEFAULT '{}',
    
    -- AI confidence score (0-1)
    confidence FLOAT DEFAULT 1.0,
    
    -- Source: 'ai' or 'manual'
    source VARCHAR(10) DEFAULT 'ai',
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. ENABLE RLS ON response_tags
-- =========================================================================
ALTER TABLE response_tags ENABLE ROW LEVEL SECURITY;

-- RLS: Users can view tags on their family's responses
CREATE POLICY "Users can view response tags" ON response_tags
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM responses 
            WHERE responses.id = response_tags.response_id 
            AND responses.user_id IN (SELECT id FROM profiles WHERE family_id IN (SELECT family_id FROM profiles WHERE auth_user_id = auth.uid()))
        )
    );

CREATE POLICY "Users can insert response tags" ON response_tags
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM responses 
            WHERE responses.id = response_tags.response_id 
            AND responses.user_id IN (SELECT id FROM profiles WHERE family_id IN (SELECT family_id FROM profiles WHERE auth_user_id = auth.uid()))
        )
    );

CREATE POLICY "Users can update response tags" ON response_tags
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM responses 
            WHERE responses.id = response_tags.response_id 
            AND responses.user_id IN (SELECT id FROM profiles WHERE family_id IN (SELECT family_id FROM profiles WHERE auth_user_id = auth.uid()))
        )
    );

-- 4. INDEXES FOR PERFORMANCE
-- =========================================================================
CREATE INDEX idx_response_tags_response ON response_tags(response_id);
CREATE INDEX idx_response_tags_emotions ON response_tags USING gin(emotion_tags);
CREATE INDEX idx_response_tags_situations ON response_tags USING gin(situation_tags);
CREATE INDEX idx_response_tags_lessons ON response_tags USING gin(lesson_tags);
CREATE INDEX idx_response_tags_questions ON response_tags USING gin(question_keywords);
CREATE INDEX idx_responses_embedding ON responses USING ivfflat(embedding vector_cosine_ops);

-- 5. ADD EMBEDDING COLUMN TO quote_cards IF NOT EXISTS
-- =========================================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'quote_cards' AND column_name = 'embedding') THEN
        ALTER TABLE quote_cards ADD COLUMN embedding vector(1024);
    END IF;
END $$;

-- 6. HELPER FUNCTIONS FOR SEMANTIC SEARCH
-- =========================================================================

-- FUNCTION: Semantic search across responses (not stories)
CREATE OR REPLACE FUNCTION semantic_search_responses(
    p_family_id UUID,
    p_query_embedding vector(1024),
    p_limit INT DEFAULT 10,
    p_min_similarity FLOAT DEFAULT 0.3
)
RETURNS TABLE (
    response_id UUID,
    transcription_text TEXT,
    story_id UUID,
    author_name TEXT,
    author_role VARCHAR(20),
    similarity FLOAT,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.id as response_id,
        r.transcription_text,
        r.story_id,
        p.full_name as author_name,
        p.role as author_role,
        1 - (r.embedding <=> p_query_embedding) as similarity,
        r.created_at
    FROM responses r
    JOIN profiles p ON r.user_id = p.id
    WHERE p.family_id = p_family_id
    AND r.embedding IS NOT NULL
    AND r.transcription_text IS NOT NULL
    AND r.transcription_text != ''
    AND (1 - (r.embedding <=> p_query_embedding)) >= p_min_similarity
    ORDER BY similarity DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- FUNCTION: Aggregate response tags to story level (for story view)
CREATE OR REPLACE FUNCTION aggregate_response_tags_to_story(p_story_id UUID)
RETURNS TABLE (
    emotion_tags TEXT[],
    situation_tags TEXT[],
    lesson_tags TEXT[],
    guidance_tags TEXT[],
    question_keywords TEXT[]
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        array_agg(DISTINCT unnest(rt.emotion_tags)) FILTER (WHERE unnest IS NOT NULL) as emotion_tags,
        array_agg(DISTINCT unnest(rt.situation_tags)) FILTER (WHERE unnest IS NOT NULL) as situation_tags,
        array_agg(DISTINCT unnest(rt.lesson_tags)) FILTER (WHERE unnest IS NOT NULL) as lesson_tags,
        array_agg(DISTINCT unnest(rt.guidance_tags)) FILTER (WHERE unnest IS NOT NULL) as guidance_tags,
        array_agg(DISTINCT unnest(rt.question_keywords)) FILTER (WHERE unnest IS NOT NULL) as question_keywords
    FROM responses r
    JOIN response_tags rt ON r.id = rt.response_id
    WHERE r.story_id = p_story_id;
END;
$$ LANGUAGE plpgsql;

-- FUNCTION: Search wisdom across responses
CREATE OR REPLACE FUNCTION search_wisdom_in_responses(
    p_family_id UUID,
    p_search_query TEXT,
    p_limit INT DEFAULT 10
)
RETURNS TABLE (
    response_id UUID,
    story_id UUID,
    story_title TEXT,
    transcription_text TEXT,
    author_name TEXT,
    author_role VARCHAR(20),
    emotion_tags TEXT[],
    situation_tags TEXT[],
    lesson_tags TEXT[],
    guidance_tags TEXT[],
    match_score FLOAT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.id as response_id,
        r.story_id,
        s.title as story_title,
        r.transcription_text,
        p.full_name as author_name,
        p.role as author_role,
        rt.emotion_tags,
        rt.situation_tags,
        rt.lesson_tags,
        rt.guidance_tags,
        (
            CASE WHEN rt.emotion_tags && string_to_array(lower(p_search_query), ' ') THEN 1.0 ELSE 0.0 END +
            CASE WHEN rt.situation_tags && string_to_array(lower(p_search_query), ' ') THEN 1.0 ELSE 0.0 END +
            CASE WHEN rt.lesson_tags && string_to_array(lower(p_search_query), ' ') THEN 1.0 ELSE 0.0 END +
            CASE WHEN rt.question_keywords && string_to_array(lower(p_search_query), ' ') THEN 1.5 ELSE 0.0 END
        ) as match_score
    FROM responses r
    JOIN profiles p ON r.user_id = p.id
    LEFT JOIN stories s ON r.story_id = s.id
    LEFT JOIN response_tags rt ON r.id = rt.response_id
    WHERE p.family_id = p_family_id
    AND r.transcription_text IS NOT NULL
    AND r.transcription_text != ''
    AND (
        (rt.emotion_tags && string_to_array(lower(p_search_query), ' ')) OR
        (rt.situation_tags && string_to_array(lower(p_search_query), ' ')) OR
        (rt.lesson_tags && string_to_array(lower(p_search_query), ' ')) OR
        (rt.question_keywords && string_to_array(lower(p_search_query), ' ')) OR
        (r.transcription_text ILIKE '%' || p_search_query || '%')
    )
    ORDER BY match_score DESC, r.created_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- 7. BACKFILL: Copy existing story_tags to response_tags for stories with single response
-- =========================================================================
-- This is optional - for existing stories, you may want to manually trigger re-tagging
-- of responses to migrate to the new response-level system

-- 8. ADD EMBEDDING COLUMN TO responses IF NOT EXISTS (for pgvector)
-- =========================================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'responses' AND column_name = 'embedding') THEN
        ALTER TABLE responses ADD COLUMN embedding vector(1024);
    END IF;
END $$;

COMMENT ON COLUMN responses.embedding IS '1024-dimensional vector embedding of transcription_text for semantic search';
COMMENT ON TABLE response_tags IS 'Wisdom tags for individual responses (emotions, situations, lessons, guidance)';
