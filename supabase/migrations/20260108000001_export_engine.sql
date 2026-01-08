
-- =========================================================================
-- EXPORT ENGINE - Multi-format export for value extraction
--
-- Purpose: Enable users to export stories and collections in various formats
-- for backup, sharing, and archival purposes
--
-- Tables added:
--   - exports: Track export jobs and results
-- =========================================================================

-- 1. EXPORTS TABLE
-- =========================================================================
-- Track all export requests and their results

CREATE TABLE exports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    family_id UUID REFERENCES families(id) ON DELETE CASCADE,

    -- What was exported
    target_type VARCHAR(20) NOT NULL, -- 'story' or 'collection'
    target_id UUID NOT NULL,

    -- Export format
    format VARCHAR(10) NOT NULL, -- 'pdf', 'audio', 'video', 'json', 'epub'

    -- Export options (what was included)
    options JSONB DEFAULT '{}',

    -- Result
    status VARCHAR(20) NOT NULL DEFAULT 'pending', -- 'pending', 'processing', 'completed', 'failed'
    file_url TEXT,
    file_size_bytes BIGINT,
    error_message TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- 2. ROW LEVEL SECURITY (RLS) POLICIES
-- =========================================================================

ALTER TABLE exports ENABLE ROW LEVEL SECURITY;

-- Users can view their own exports
CREATE POLICY "Users can view own exports" ON exports
    FOR SELECT USING (user_id = (SELECT id FROM profiles WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can insert exports" ON exports
    FOR INSERT WITH CHECK (user_id = (SELECT id FROM profiles WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can delete own exports" ON exports
    FOR DELETE USING (user_id = (SELECT id FROM profiles WHERE auth_user_id = auth.uid()));

-- 3. INDEXES (Performance)
-- =========================================================================

CREATE INDEX idx_exports_user ON exports(user_id);
CREATE INDEX idx_exports_family ON exports(family_id);
CREATE INDEX idx_exports_target ON exports(target_type, target_id);
CREATE INDEX idx_exports_status ON exports(status);
CREATE INDEX idx_exports_format ON exports(format);
CREATE INDEX idx_exports_created ON exports(created_at DESC);

-- 4. VIEWS (Common Queries)
-- =========================================================================

-- VIEW: exports_with_details
-- Returns exports with story/collection details
CREATE VIEW exports_with_details AS
SELECT
    e.id,
    e.user_id,
    e.target_type,
    e.target_id,
    e.format,
    e.options,
    e.status,
    e.file_url,
    e.file_size_bytes,
    e.error_message,
    e.created_at,
    e.completed_at,
    -- Join with story/collection for details
    CASE
        WHEN e.target_type = 'story' THEN
            (SELECT title FROM stories WHERE id = e.target_id)
        WHEN e.target_type = 'collection' THEN
            (SELECT title FROM collections WHERE id = e.target_id)
        ELSE NULL
    END as item_title
FROM exports e;

-- 5. GRANTS (Permissions)
-- =========================================================================

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon;
GRANT SELECT ON exports TO authenticated;

-- 6. FUNCTIONS (Export helpers)
-- =========================================================================

-- FUNCTION: track_export
-- Record a new export job
CREATE OR REPLACE FUNCTION track_export(
    p_user_id UUID,
    p_target_type VARCHAR(20),
    p_target_id UUID,
    p_format VARCHAR(10),
    p_options JSONB
)
RETURNS UUID AS $$
DECLARE
    v_export_id UUID;
BEGIN
    INSERT INTO exports (
        user_id,
        target_type,
        target_id,
        format,
        options
    )
    VALUES (
        p_user_id,
        p_target_type,
        p_target_id,
        p_format,
        p_options
    )
    RETURNING id INTO v_export_id;

    RETURN v_export_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- FUNCTION: complete_export
-- Mark an export as completed
CREATE OR REPLACE FUNCTION complete_export(
    p_export_id UUID,
    p_file_url TEXT,
    p_file_size BIGINT
)
RETURNS VOID AS $$
BEGIN
    UPDATE exports
    SET
        status = 'completed',
        file_url = p_file_url,
        file_size_bytes = p_file_size,
        completed_at = NOW()
    WHERE id = p_export_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- FUNCTION: fail_export
-- Mark an export as failed
CREATE OR REPLACE FUNCTION fail_export(
    p_export_id UUID,
    p_error_message TEXT
)
RETURNS VOID AS $$
BEGIN
    UPDATE exports
    SET
        status = 'failed',
        error_message = p_error_message,
        completed_at = NOW()
    WHERE id = p_export_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. COMMENTS (Documentation)
-- =========================================================================

COMMENT ON TABLE exports IS 'Track all export jobs and their results';
COMMENT ON COLUMN exports.format IS 'Export format: pdf, audio, video, json, epub';
COMMENT ON COLUMN exports.options IS 'Export-specific options (includeImages, quality, etc.)';
COMMENT ON COLUMN exports.file_url IS 'Download URL for completed export';
COMMENT ON COLUMN exports.status IS 'pending, processing, completed, failed';
