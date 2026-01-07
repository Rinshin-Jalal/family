-- =========================================================================
-- STORYRD - ANALYTICS & FEATURE FLAGS
-- Adds: analytics_events, feature_flags tables
-- =========================================================================

-- 1. ANALYTICS EVENTS - Track user behavior
-- =========================================================================
CREATE TABLE analytics_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Event identification
    event_type VARCHAR(100) NOT NULL,
    event_category VARCHAR(50) NOT NULL,
    
    -- User context
    user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    session_id UUID,
    
    -- Event data
    event_properties JSONB DEFAULT '{}',
    page_url TEXT,
    referrer_url TEXT,
    
    -- Device context
    platform VARCHAR(20),  -- 'ios', 'android', 'web'
    app_version VARCHAR(20),
    device_id VARCHAR(100),
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. DAILY METRICS - Aggregated daily stats
-- =========================================================================
CREATE TABLE daily_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    metric_date DATE NOT NULL,
    metric_type VARCHAR(50) NOT NULL,
    family_id UUID REFERENCES families(id) ON DELETE CASCADE,
    
    -- Metrics
    count INT DEFAULT 0,
    unique_users INT DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(metric_date, metric_type, family_id)
);

-- 3. FEATURE FLAGS - Feature gating by plan tier
-- =========================================================================
CREATE TABLE feature_flags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    feature_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    
    -- Feature flag config
    is_enabled BOOLEAN DEFAULT TRUE,
    minimum_plan_tier VARCHAR(20) DEFAULT 'starter',  -- 'free', 'starter', 'standard', 'extended'
    
    -- Rollout percentage (0-100)
    rollout_percentage INT DEFAULT 100,
    
    -- Targeting
    target_segments TEXT[],  -- ['teen', 'parent', 'child', 'elder']
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. ENABLE RLS
-- =========================================================================
ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE feature_flags ENABLE ROW LEVEL SECURITY;

-- ANALYTICS_EVENTS: Self-service access
CREATE POLICY "Users can view own events" ON analytics_events
    FOR SELECT USING (
        user_id IN (SELECT id FROM profiles WHERE auth_user_id = auth.uid())
        OR user_id IS NULL
    );

CREATE POLICY "Users can insert events" ON analytics_events
    FOR INSERT WITH CHECK (true);  -- Allow anonymous events

-- DAILY_METRICS: View own family's metrics
CREATE POLICY "View family metrics" ON daily_metrics
    FOR SELECT USING (
        family_id IN (SELECT family_id FROM profiles WHERE auth_user_id = auth.uid())
        OR family_id IS NULL
    );

CREATE POLICY "Insert family metrics" ON daily_metrics
    FOR INSERT WITH CHECK (
        family_id IN (SELECT family_id FROM profiles WHERE auth_user_id = auth.uid())
        OR family_id IS NULL
    );

CREATE POLICY "Update family metrics" ON daily_metrics
    FOR UPDATE USING (
        family_id IN (SELECT family_id FROM profiles WHERE auth_user_id = auth.uid())
        OR family_id IS NULL
    );

-- FEATURE_FLAGS: Read-only access
CREATE POLICY "View feature flags" ON feature_flags
    FOR SELECT USING (true);

CREATE POLICY "Update feature flags" ON feature_flags
    FOR UPDATE USING (true);

-- 5. INDEXES
-- =========================================================================
CREATE INDEX idx_events_user ON analytics_events(user_id, created_at);
CREATE INDEX idx_events_session ON analytics_events(session_id, created_at);
CREATE INDEX idx_events_type ON analytics_events(event_type, created_at);
CREATE INDEX idx_events_category ON analytics_events(event_category, created_at);

CREATE INDEX idx_daily_metrics_date ON daily_metrics(metric_date, metric_type);
CREATE INDEX idx_daily_metrics_family ON daily_metrics(family_id);

-- 6. HELPER FUNCTIONS
-- =========================================================================

-- FUNCTION: Track an analytics event
CREATE OR REPLACE FUNCTION track_event(
    p_event_type VARCHAR,
    p_event_category VARCHAR,
    p_user_id UUID,
    p_session_id UUID,
    p_properties JSONB,
    p_platform VARCHAR
) RETURNS void AS $$
BEGIN
    INSERT INTO analytics_events (
        event_type,
        event_category,
        user_id,
        session_id,
        event_properties,
        platform
    ) VALUES (
        p_event_type,
        p_event_category,
        p_user_id,
        p_session_id,
        p_properties,
        p_platform
    );
END;
$$ LANGUAGE plpgsql;

-- FUNCTION: Check if feature is enabled for user
CREATE OR REPLACE FUNCTION is_feature_enabled(
    p_feature_name VARCHAR,
    p_user_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
    v_flag RECORD;
    v_user RECORD;
    v_plan_tier VARCHAR(20);
    v_rollout INT;
BEGIN
    -- Get feature flag
    SELECT * INTO v_flag FROM feature_flags WHERE feature_name = p_feature_name;
    
    IF NOT FOUND OR NOT v_flag.is_enabled THEN
        RETURN FALSE;
    END IF;
    
    -- Get user plan tier
    SELECT plan_tier INTO v_plan_tier
    FROM profiles WHERE id = p_user_id;
    
    -- Check plan tier requirement
    IF v_plan_tier IS NULL OR v_plan_tier < v_flag.minimum_plan_tier THEN
        RETURN FALSE;
    END IF;
    
    -- Check rollout percentage
    v_rollout := v_flag.rollout_percentage;
    IF v_rollout < 100 AND (p_user_id::text::uuid % 100) >= v_rollout THEN
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- FUNCTION: Increment daily metric
CREATE OR REPLACE FUNCTION increment_daily_metric(
    p_metric_date DATE,
    p_metric_type VARCHAR,
    p_family_id UUID,
    p_increment INT DEFAULT 1
) RETURNS void AS $$
BEGIN
    INSERT INTO daily_metrics (metric_date, metric_type, family_id, count, unique_users)
    VALUES (p_metric_date, p_metric_type, p_family_id, p_increment, 1)
    ON CONFLICT (metric_date, metric_type, family_id)
    DO UPDATE SET 
        count = daily_metrics.count + p_increment,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- FUNCTION: Get popular stories this week
CREATE OR REPLACE FUNCTION get_popular_stories(
    p_family_id UUID,
    p_limit INT DEFAULT 10
) RETURNS TABLE (
    story_id UUID,
    title TEXT,
    views INT,
    shares INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ae.event_properties->>'story_id' as story_id,
        ae.event_properties->>'story_title' as title,
        COUNT(*) FILTER (WHERE ae.event_type = 'story_view') as views,
        COUNT(*) FILTER (WHERE ae.event_type = 'story_share') as shares
    FROM analytics_events ae
    JOIN profiles p ON p.id = ae.user_id
    WHERE p.family_id = p_family_id
    AND ae.event_type IN ('story_view', 'story_share')
    AND ae.created_at > NOW() - INTERVAL '7 days'
    GROUP BY ae.event_properties->>'story_id', ae.event_properties->>'story_title'
    ORDER BY views DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- 7. SEED DEFAULT FEATURE FLAGS
-- =========================================================================
INSERT INTO feature_flags (feature_name, description, minimum_plan_tier, rollout_percentage) VALUES
('quote_cards', 'Shareable wisdom quote cards', 'free', 100),
('family_polls', 'Family voting and polls', 'free', 100),
('wisdom_search', 'AI-powered wisdom search', 'free', 100),
('ai_wisdom_coach', 'Conversational AI wisdom coach', 'standard', 100),
('trivia_game', 'Family trivia game', 'standard', 100),
('year_map', 'Family journey timeline map', 'standard', 50),
('location_tagging', 'Auto-tag story locations', 'standard', 100),
('export_data', 'Export family data', 'standard', 100),
('unlimited_storage', 'Unlimited story storage', 'extended', 100),
('priority_support', 'Priority customer support', 'extended', 100)
ON CONFLICT (feature_name) DO NOTHING;

-- 8. EVENT TYPES CONSTANT
-- =========================================================================
COMMENT ON TABLE analytics_events IS 'Track user behavior and engagement events';
COMMENT ON TABLE daily_metrics IS 'Aggregated daily metrics for analytics dashboard';
COMMENT ON TABLE feature_flags IS 'Feature flags for tier-based access control';

