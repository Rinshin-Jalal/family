-- =========================================================================
-- STORYRD - WISDOM TAGS SYSTEM
-- Adds: story_tags, wisdom_requests, wisdom_summaries tables
-- =========================================================================

-- 1. WISDOM TAGS - Auto-tag stories with emotions/situations/lessons
-- =========================================================================
CREATE TABLE story_tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    story_id UUID REFERENCES stories(id) ON DELETE CASCADE NOT NULL,
    
    -- Tag categories for wisdom search
    emotion_tags TEXT[] DEFAULT '{}',        -- ['anxiety', 'fear', 'joy', 'grief', 'hope', 'love']
    situation_tags TEXT[] DEFAULT '{}',      -- ['divorce', 'job-loss', 'money', 'first-job', 'immigration']
    lesson_tags TEXT[] DEFAULT '{}',         -- ['survival', 'hope', 'resilience', 'family-togetherness']
    guidance_tags TEXT[] DEFAULT '{}',       -- ['what-to-do', 'what-not-to-do', 'advice']
    
    -- Searchable question keywords
    question_keywords TEXT[] DEFAULT '{}',   -- ['how did family handle money', 'divorce advice', 'job loss']
    
    -- AI confidence score (0-1)
    confidence FLOAT DEFAULT 1.0,
    
    -- Source: 'ai' or 'manual'
    source VARCHAR(10) DEFAULT 'ai',
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. WISDOM REQUESTS - Request stories from family members
-- =========================================================================
CREATE TYPE request_status AS ENUM ('pending', 'accepted', 'completed', 'declined');

CREATE TABLE wisdom_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- The question being asked
    question TEXT NOT NULL,
    
    -- Who asked (can be NULL if from AI/auto-request)
    requester_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    
    -- Target family members to respond
    target_profile_ids UUID[] NOT NULL DEFAULT '{}',
    
    -- If request is linked to a story (context)
    related_story_id UUID REFERENCES stories(id) ON DELETE SET NULL,
    
    -- Request status
    status request_status DEFAULT 'pending',
    
    -- When the request expires (auto-expire after 7 days)
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '7 days'),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. WISDOM SUMMARIES - AI-generated wisdom summaries for stories
-- =========================================================================
CREATE TABLE wisdom_summaries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    story_id UUID REFERENCES stories(id) ON DELETE CASCADE NOT NULL,
    
    -- The AI-generated summary
    summary_text TEXT NOT NULL,
    
    -- Structured insights
    what_happened TEXT[],           -- ['job loss', 'moved to new city', 'struggled financially']
    what_learned TEXT[],            -- ['persistence matters', 'family support is key']
    guidance TEXT[],                -- ['stay positive', 'ask for help', 'take risks']
    
    -- For "Me vs. Family" comparisons
    generation VARCHAR(50),         -- 'grandma', 'grandpa', 'uncle', 'mom', 'dad'
    year_range VARCHAR(20),         -- '1970s', '1980s', '1990s', '2000s'
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. WISDOM SEARCH LOG - Track searches for analytics
-- =========================================================================
CREATE TABLE wisdom_search_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    
    search_query TEXT NOT NULL,
    stories_found INT DEFAULT 0,
    requests_sent INT DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. ENABLE RLS ON NEW TABLES
-- =========================================================================
ALTER TABLE story_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE wisdom_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE wisdom_summaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE wisdom_search_logs ENABLE ROW LEVEL SECURITY;

-- STORY_TAGS: Users can view tags on their family's stories
CREATE POLICY "Users can view story tags" ON story_tags
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM stories 
            WHERE stories.id = story_tags.story_id 
            AND stories.family_id IN (SELECT family_id FROM profiles WHERE auth_user_id = auth.uid())
        )
    );

CREATE POLICY "Users can insert story tags" ON story_tags
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM stories 
            WHERE stories.id = story_tags.story_id 
            AND stories.family_id IN (SELECT family_id FROM profiles WHERE auth_user_id = auth.uid())
        )
    );

CREATE POLICY "Users can update story tags" ON story_tags
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM stories 
            WHERE stories.id = story_tags.story_id 
            AND stories.family_id IN (SELECT family_id FROM profiles WHERE auth_user_id = auth.uid())
        )
    );

-- WISDOM_REQUESTS: Users can view requests in their family
CREATE POLICY "Users can view wisdom requests" ON wisdom_requests
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = wisdom_requests.requester_id 
            AND profiles.family_id IN (SELECT family_id FROM profiles WHERE auth_user_id = auth.uid())
        )
        OR
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = ANY(wisdom_requests.target_profile_ids)
            AND profiles.family_id IN (SELECT family_id FROM profiles WHERE auth_user_id = auth.uid())
        )
    );

CREATE POLICY "Users can insert wisdom requests" ON wisdom_requests
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = requester_id 
            AND profiles.family_id IN (SELECT family_id FROM profiles WHERE auth_user_id = auth.uid())
        )
        OR requester_id IS NULL  -- AI-initiated requests
    );

CREATE POLICY "Users can update wisdom requests" ON wisdom_requests
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = wisdom_requests.requester_id 
            AND profiles.family_id IN (SELECT family_id FROM profiles WHERE auth_user_id = auth.uid())
        )
    );

-- WISDOM_SUMMARIES: Users can view summaries on their family's stories
CREATE POLICY "Users can view wisdom summaries" ON wisdom_summaries
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM stories 
            WHERE stories.id = wisdom_summaries.story_id 
            AND stories.family_id IN (SELECT family_id FROM profiles WHERE auth_user_id = auth.uid())
        )
    );

CREATE POLICY "Users can insert wisdom summaries" ON wisdom_summaries
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM stories 
            WHERE stories.id = wisdom_summaries.story_id 
            AND stories.family_id IN (SELECT family_id FROM profiles WHERE auth_user_id = auth.uid())
        )
    );

-- WISDOM_SEARCH_LOGS: Users can view their own search logs
CREATE POLICY "Users can view own search logs" ON wisdom_search_logs
    FOR SELECT USING (
        user_id IN (SELECT id FROM profiles WHERE auth_user_id = auth.uid())
    );

CREATE POLICY "Users can insert search logs" ON wisdom_search_logs
    FOR INSERT WITH CHECK (
        user_id IN (SELECT id FROM profiles WHERE auth_user_id = auth.uid())
        OR user_id IS NULL  -- Anonymous searches
    );

-- 6. INDEXES FOR PERFORMANCE
-- =========================================================================
create index idx_story_tags_story on story_tags(story_id);
create index idx_story_tags_emotions on story_tags using gin(emotion_tags);
create index idx_story_tags_situations on story_tags using gin(situation_tags);
create index idx_story_tags_lessons on story_tags using gin(lesson_tags);
create index idx_story_tags_questions on story_tags using gin(question_keywords);

create index idx_wisdom_requests_requester on wisdom_requests(requester_id);
create index idx_wisdom_requests_status on wisdom_requests(status);
create index idx_wisdom_requests_expires on wisdom_requests(expires_at);

create index idx_wisdom_summaries_story on wisdom_summaries(story_id);
create index idx_wisdom_summaries_generation on wisdom_summaries(generation);

create index idx_search_logs_user on wisdom_search_logs(user_id);
create index idx_search_logs_created on wisdom_search_logs(created_at);

-- 7. HELPER FUNCTIONS
-- =========================================================================

-- FUNCTION: Search wisdom by query text
-- Searches across emotion_tags, situation_tags, lesson_tags, and question_keywords
CREATE OR REPLACE FUNCTION search_wisdom_by_query(
    p_family_id UUID,
    p_search_query TEXT,
    p_limit INT DEFAULT 10
)
RETURNS TABLE (
    story_id UUID,
    title TEXT,
    summary_text TEXT,
    cover_image_url TEXT,
    prompt_text TEXT,
    emotion_tags TEXT[],
    situation_tags TEXT[],
    lesson_tags TEXT[],
    match_score FLOAT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id,
        s.title,
        s.summary_text,
        s.cover_image_url,
        p.text as prompt_text,
        t.emotion_tags,
        t.situation_tags,
        t.lesson_tags,
        -- Calculate match score based on tag overlap
        (
            CASE WHEN t.emotion_tags && string_to_array(lower(p_search_query), ' ') THEN 1.0 ELSE 0.0 END +
            CASE WHEN t.situation_tags && string_to_array(lower(p_search_query), ' ') THEN 1.0 ELSE 0.0 END +
            CASE WHEN t.lesson_tags && string_to_array(lower(p_search_query), ' ') THEN 1.0 ELSE 0.0 END +
            CASE WHEN t.question_keywords && string_to_array(lower(p_search_query), ' ') THEN 1.5 ELSE 0.0 END
        ) as match_score
    FROM stories s
    LEFT JOIN prompts p ON s.prompt_id = p.id
    LEFT JOIN story_tags t ON s.id = t.story_id
    WHERE s.family_id = p_family_id
    AND (
        -- Match on tags
        (t.emotion_tags && string_to_array(lower(p_search_query), ' ')) OR
        (t.situation_tags && string_to_array(lower(p_search_query), ' ')) OR
        (t.lesson_tags && string_to_array(lower(p_search_query), ' ')) OR
        (t.question_keywords && string_to_array(lower(p_search_query), ' ')) OR
        -- Fallback: match on story summary or prompt text
        (s.summary_text ILIKE '%' || p_search_query || '%') OR
        (p.text ILIKE '%' || p_search_query || '%')
    )
    ORDER BY match_score DESC, s.created_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- FUNCTION: Auto-generate tags for a story
CREATE OR REPLACE FUNCTION auto_tag_story(p_story_id UUID)
RETURNS void AS $$
DECLARE
    v_transcription TEXT;
    v_emotion_tags TEXT[];
    v_situation_tags TEXT[];
    v_lesson_tags TEXT[];
    v_question_keywords TEXT[];
BEGIN
    -- Get all transcriptions for this story
    SELECT string_agg(transcription_text, ' ') INTO v_transcription
    FROM responses
    WHERE story_id = p_story_id;

    -- Call AI tagging service (implemented in app layer)
    -- Tags will be inserted via API call to /api/stories/:id/tag
    -- This function serves as a placeholder for future AI integration
    
    RAISE NOTICE 'Story % ready for auto-tagging', p_story_id;
END;
$$ LANGUAGE plpgsql;

-- FUNCTION: Check if a wisdom request has expired
CREATE OR REPLACE FUNCTION is_request_expired(p_request_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_expires_at TIMESTAMPTZ;
BEGIN
    SELECT expires_at INTO v_expires_at FROM wisdom_requests WHERE id = p_request_id;
    RETURN v_expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- FUNCTION: Get pending requests for a user
CREATE OR REPLACE FUNCTION get_pending_requests_for_user(p_profile_id UUID)
RETURNS TABLE (
    id UUID,
    question TEXT,
    requester_name TEXT,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        wr.id,
        wr.question,
        p.full_name as requester_name,
        wr.created_at
    FROM wisdom_requests wr
    JOIN profiles p ON wr.requester_id = p.id
    WHERE p_profile_id = ANY(wr.target_profile_ids)
    AND wr.status = 'pending'
    AND wr.expires_at > NOW()
    ORDER BY wr.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- 8. TRIGGERS
-- =========================================================================

-- Auto-create tags when a story is completed
CREATE OR REPLACE FUNCTION trigger_auto_tag_on_story_complete()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_completed = TRUE AND OLD.is_completed = FALSE THEN
        PERFORM auto_tag_story(NEW.id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_story_completed
    AFTER UPDATE ON stories
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_auto_tag_on_story_complete();

