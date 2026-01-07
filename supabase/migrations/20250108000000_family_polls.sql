-- =========================================================================
-- STORYRD - FAMILY POLLS FEATURE
-- Adds: polls, poll_options, poll_votes tables
-- =========================================================================

-- 1. POLLS - Family polls for engagement
-- =========================================================================
CREATE TABLE polls (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Poll content
    question TEXT NOT NULL,
    description TEXT,
    
    -- AI-generated poll from stories (optional)
    story_id UUID REFERENCES stories(id) ON DELETE SET NULL,
    
    -- Poll configuration
    poll_type VARCHAR(20) DEFAULT 'generational',  -- 'generational', 'opinion', 'trivia'
    allows_multiple BOOLEAN DEFAULT FALSE,
    requires_justification BOOLEAN DEFAULT FALSE,
    
    -- Timing
    starts_at TIMESTAMPTZ DEFAULT NOW(),
    ends_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '3 days'),
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    show_results BOOLEAN DEFAULT TRUE,
    
    -- Metadata
    created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    family_id UUID REFERENCES families(id) ON DELETE CASCADE NOT NULL,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. POLL OPTIONS - Answer choices
-- =========================================================================
CREATE TABLE poll_options (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    poll_id UUID REFERENCES polls(id) ON DELETE CASCADE NOT NULL,
    
    -- Option content
    option_text TEXT NOT NULL,
    option_label VARCHAR(10) NOT NULL,  -- 'A', 'B', 'C', 'D'
    
    -- Generation-specific options (for generational polls)
    generation VARCHAR(50),  -- 'grandparents', 'parents', 'kids', 'everyone'
    
    -- Sort order
    display_order INT DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. POLL VOTES - Individual votes
-- =========================================================================
CREATE TABLE poll_votes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    poll_id UUID REFERENCES polls(id) ON DELETE CASCADE NOT NULL,
    option_id UUID REFERENCES poll_options(id) ON DELETE CASCADE NOT NULL,
    voter_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- Vote metadata
    justification TEXT,  -- Optional reason for vote
    generation VARCHAR(50),  -- Voter's generation for generational polls
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(poll_id, voter_id)  -- One vote per poll per user
);

-- 4. ENABLE RLS ON POLL TABLES
-- =========================================================================
ALTER TABLE polls ENABLE ROW LEVEL SECURITY;
ALTER TABLE poll_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE poll_votes ENABLE ROW LEVEL SECURITY;

-- POLLS: View active polls for family
CREATE POLICY "Family members can view polls" ON polls
    FOR SELECT USING (
        family_id IN (SELECT family_id FROM profiles WHERE auth_user_id = auth.uid())
    );

CREATE POLICY "Family members can create polls" ON polls
    FOR INSERT WITH CHECK (
        family_id IN (SELECT family_id FROM profiles WHERE auth_user_id = auth.uid())
    );

CREATE POLICY "Poll creators can update polls" ON polls
    FOR UPDATE USING (
        created_by IN (SELECT id FROM profiles WHERE auth_user_id = auth.uid())
    );

-- POLL_OPTIONS: View options for family's polls
CREATE POLICY "View poll options" ON poll_options
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM polls
            WHERE polls.id = poll_options.poll_id
            AND polls.family_id IN (SELECT family_id FROM profiles WHERE auth_user_id = auth.uid())
        )
    );

CREATE POLICY "Create poll options" ON poll_options
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM polls
            WHERE polls.id = poll_options.poll_id
            AND polls.family_id IN (SELECT family_id FROM profiles WHERE auth_user_id = auth.uid())
        )
    );

-- POLL_VOTES: View and vote on family's polls
CREATE POLICY "View poll votes" ON poll_votes
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM polls
            WHERE polls.id = poll_votes.poll_id
            AND polls.family_id IN (SELECT family_id FROM profiles WHERE auth_user_id = auth.uid())
        )
    );

CREATE POLICY "Vote on polls" ON poll_votes
    FOR INSERT WITH CHECK (
        voter_id IN (SELECT id FROM profiles WHERE auth_user_id = auth.uid())
    );

CREATE POLICY "Update own vote" ON poll_votes
    FOR UPDATE USING (
        voter_id IN (SELECT id FROM profiles WHERE auth_user_id = auth.uid())
    );

-- 5. INDEXES FOR PERFORMANCE
-- =========================================================================
CREATE INDEX idx_polls_family ON polls(family_id);
CREATE INDEX idx_polls_active ON polls(is_active, starts_at, ends_at);
CREATE INDEX idx_polls_story ON polls(story_id);

CREATE INDEX idx_poll_options_poll ON poll_options(poll_id, display_order);

CREATE INDEX idx_poll_votes_poll ON poll_votes(poll_id);
CREATE INDEX idx_poll_votes_voter ON poll_votes(voter_id);

-- 6. HELPER FUNCTIONS
-- =========================================================================

-- FUNCTION: Get active polls for a family
CREATE OR REPLACE FUNCTION get_active_polls(p_family_id UUID)
RETURNS TABLE (
    id UUID,
    question TEXT,
    description TEXT,
    poll_type VARCHAR,
    ends_at TIMESTAMPTZ,
    options JSONB,
    has_voted BOOLEAN,
    total_votes INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id,
        p.question,
        p.description,
        p.poll_type,
        p.ends_at,
        (
            SELECT json_agg(
                json_build_object(
                    'id', po.id,
                    'text', po.option_text,
                    'label', po.option_label,
                    'generation', po.generation,
                    'vote_count', (SELECT COUNT(*) FROM poll_votes WHERE option_id = po.id)
                ) ORDER BY po.display_order
            )
            FROM poll_options po
            WHERE po.poll_id = p.id
        ) as options,
        EXISTS (
            SELECT 1 FROM poll_votes pv
            WHERE pv.poll_id = p.id
            AND pv.voter_id = (SELECT id FROM profiles WHERE auth_user_id = auth.uid() LIMIT 1)
        ) as has_voted,
        (SELECT COUNT(*) FROM poll_votes WHERE poll_id = p.id) as total_votes
    FROM polls p
    WHERE p.family_id = p_family_id
    AND p.is_active = TRUE
    AND p.ends_at > NOW()
    ORDER BY p.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- FUNCTION: Get poll results with generation breakdown
CREATE OR REPLACE FUNCTION get_poll_results(p_poll_id UUID)
RETURNS TABLE (
    option_id UUID,
    option_text TEXT,
    option_label VARCHAR,
    generation VARCHAR,
    vote_count INT,
    generation_count INT,
    percentage FLOAT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        po.id,
        po.option_text,
        po.option_label,
        po.generation,
        COUNT(pv.id) as vote_count,
        COUNT(pv.id) FILTER (WHERE pv.generation = po.generation) as generation_count,
        CASE
            WHEN (SELECT COUNT(*) FROM poll_votes WHERE poll_id = p_poll_id) > 0
            THEN (COUNT(pv.id)::FLOAT / (SELECT COUNT(*) FROM poll_votes WHERE poll_id = p_poll_id)) * 100
            ELSE 0
        END as percentage
    FROM poll_options po
    LEFT JOIN poll_votes pv ON pv.option_id = po.id
    WHERE po.poll_id = p_poll_id
    GROUP BY po.id, po.option_text, po.option_label, po.generation
    ORDER BY po.display_order;
END;
$$ LANGUAGE plpgsql;

-- FUNCTION: Check if user has voted on poll
CREATE OR REPLACE FUNCTION has_voted_on_poll(p_poll_id UUID, p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_count INT;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM poll_votes
    WHERE poll_id = p_poll_id AND voter_id = p_user_id;
    RETURN v_count > 0;
END;
$$ LANGUAGE plpgsql;

-- FUNCTION: Get user's vote on a poll
CREATE OR REPLACE FUNCTION get_user_vote(p_poll_id UUID, p_user_id UUID)
RETURNS TABLE (
    option_id UUID,
    option_text TEXT,
    justification TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        pv.option_id,
        po.option_text,
        pv.justification
    FROM poll_votes pv
    JOIN poll_options po ON po.id = pv.option_id
    WHERE pv.poll_id = p_poll_id AND pv.voter_id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- FUNCTION: Generate AI poll from story
CREATE OR REPLACE FUNCTION generate_poll_from_story(p_story_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_poll_id UUID;
    v_result JSONB;
BEGIN
    -- This is a placeholder - actual AI generation happens in app layer
    -- The app layer calls AI to generate poll question and options
    -- Then inserts into polls and poll_options tables
    
    v_result := jsonb_build_object(
        'status', 'ready',
        'story_id', p_story_id,
        'message', 'Poll generation would be triggered via API call'
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- 7. TRIGGERS
-- =========================================================================

-- Auto-close polls when they expire
CREATE OR REPLACE FUNCTION trigger_poll_expiry()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.ends_at <= NOW() AND OLD.ends_at > NOW() THEN
        UPDATE polls SET is_active = FALSE WHERE id = NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_poll_expired
    AFTER UPDATE ON polls
    FOR EACH ROW
    EXECUTE PROCEDURE trigger_poll_expiry();

