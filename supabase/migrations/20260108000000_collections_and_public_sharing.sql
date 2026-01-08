
-- =========================================================================
-- COLLECTIONS & PUBLIC SHARING - Transform to "Value Extraction Tool"
--
-- Purpose: Enable no-login viewing and granular sharing controls
--
-- Tables added:
--   - collections: Bundle stories into shareable anthologies
--   - collection_stories: Join table for many-to-many relationship
--   - share_links: Public access tokens with permissions and expiration
-- =========================================================================

-- 1. COLLECTIONS TABLE
-- =========================================================================
-- Collections allow users to curate stories into themed anthologies
-- that can be exported as books, podcasts, or shared via public links

CREATE TABLE collections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    -- Collection metadata
    title TEXT NOT NULL,
    description TEXT,
    cover_image_url TEXT,

    -- Organization
    order_index INT DEFAULT 0, -- For manual ordering of collections

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. COLLECTION_STORIES JOIN TABLE
-- =========================================================================
-- Many-to-many relationship: Collections can contain many stories,
-- stories can be in multiple collections

CREATE TABLE collection_stories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    collection_id UUID NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
    story_id UUID NOT NULL REFERENCES stories(id) ON DELETE CASCADE,

    -- Custom ordering within the collection
    order_index INT NOT NULL DEFAULT 0,

    -- Optional: Add custom notes to a story within a collection
    notes TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW(),

    -- Ensure same story can only be added once to a collection
    UNIQUE(collection_id, story_id)
);

-- 3. SHARE_LINKS TABLE
-- =========================================================================
-- Public access tokens for sharing stories and collections without requiring login
-- Supports granular permissions, expiration, and watermarking

CREATE TABLE share_links (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Owner
    created_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    -- What is being shared
    target_type VARCHAR(20) NOT NULL, -- 'story' or 'collection'
    target_id UUID NOT NULL,

    -- Access control
    token TEXT UNIQUE NOT NULL, -- Public-facing token (e.g., "abc123xyz")
    password TEXT, -- Optional password protection (hashed in production)

    -- Permissions (what viewers can do)
    permissions JSONB NOT NULL DEFAULT '{
        "view": true,
        "download": false,
        "comment": false
    }'::jsonb,

    -- Watermarking for public content
    show_watermark BOOLEAN DEFAULT true,
    watermark_text TEXT, -- Custom watermark (e.g., "Shared by Rodriguez Family")

    -- Expiration
    expires_at TIMESTAMPTZ, -- NULL = no expiration
    is_active BOOLEAN DEFAULT TRUE,

    -- Usage tracking
    view_count INT DEFAULT 0,
    last_accessed_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. ROW LEVEL SECURITY (RLS) POLICIES
-- =========================================================================

ALTER TABLE collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE collection_stories ENABLE ROW LEVEL SECURITY;
ALTER TABLE share_links ENABLE ROW LEVEL SECURITY;

-- COLLECTIONS: Family members can view their family's collections
CREATE POLICY "Users can view family collections" ON collections
    FOR SELECT USING (family_id IN (SELECT family_id FROM profiles WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can create family collections" ON collections
    FOR INSERT WITH CHECK (
        family_id IN (SELECT family_id FROM profiles WHERE auth_user_id = auth.uid())
        AND created_by = (SELECT id FROM profiles WHERE auth_user_id = auth.uid())
    );

CREATE POLICY "Users can update own collections" ON collections
    FOR UPDATE USING (created_by = (SELECT id FROM profiles WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can delete own collections" ON collections
    FOR DELETE USING (created_by = (SELECT id FROM profiles WHERE auth_user_id = auth.uid()));

-- COLLECTION_STORIES: Inherit from collections
CREATE POLICY "Users can view stories in family collections" ON collection_stories
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM collections
            WHERE collections.id = collection_stories.collection_id
            AND collections.family_id IN (SELECT family_id FROM profiles WHERE auth_user_id = auth.uid())
        )
    );

CREATE POLICY "Users can add stories to own collections" ON collection_stories
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM collections
            WHERE collections.id = collection_stories.collection_id
            AND collections.created_by = (SELECT id FROM profiles WHERE auth_user_id = auth.uid())
        )
    );

CREATE POLICY "Users can remove stories from own collections" ON collection_stories
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM collections
            WHERE collections.id = collection_stories.collection_id
            AND collections.created_by = (SELECT id FROM profiles WHERE auth_user_id = auth.uid())
        )
    );

-- SHARE_LINKS: Creators can manage their own share links
CREATE POLICY "Users can view own share links" ON share_links
    FOR SELECT USING (created_by = (SELECT id FROM profiles WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can create share links" ON share_links
    FOR INSERT WITH CHECK (created_by = (SELECT id FROM profiles WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can update own share links" ON share_links
    FOR UPDATE USING (created_by = (SELECT id FROM profiles WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can delete own share links" ON share_links
    FOR DELETE USING (created_by = (SELECT id FROM profiles WHERE auth_user_id = auth.uid()));

-- 5. INDEXES (Performance)
-- =========================================================================

-- Collections indexes
CREATE INDEX idx_collections_family ON collections(family_id);
CREATE INDEX idx_collections_created_by ON collections(created_by);
CREATE INDEX idx_collections_order ON collections(order_index);

-- Collection_stories indexes
CREATE INDEX idx_collection_stories_collection ON collection_stories(collection_id);
CREATE INDEX idx_collection_stories_story ON collection_stories(story_id);
CREATE INDEX idx_collection_stories_order ON collection_stories(collection_id, order_index);

-- Share_links indexes
CREATE INDEX idx_share_links_token ON share_links(token);
CREATE INDEX idx_share_links_target ON share_links(target_type, target_id);
CREATE INDEX idx_share_links_created_by ON share_links(created_by);
CREATE INDEX idx_share_links_active ON share_links(is_active, expires_at);

-- 6. FUNCTIONS & TRIGGERS
-- =========================================================================

-- FUNCTION: generate_share_token
-- Generate a unique, URL-safe token for share links
CREATE OR REPLACE FUNCTION generate_share_token()
RETURNS TEXT AS $$
DECLARE
    token TEXT;
    exists BOOLEAN;
BEGIN
    -- Generate random 8-char token and ensure uniqueness
    LOOP
        token := lower(substring(encode(gen_random_bytes(16), 'hex'), 1, 8));

        SELECT EXISTS(SELECT 1 FROM share_links WHERE token = token) INTO exists;

        IF NOT exists THEN
            RETURN token;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- FUNCTION: increment_share_link_view_count
-- Increment view count when a share link is accessed
CREATE OR REPLACE FUNCTION increment_share_link_view_count(p_token TEXT)
RETURNS VOID AS $$
BEGIN
    UPDATE share_links
    SET view_count = view_count + 1,
        last_accessed_at = NOW()
    WHERE token = p_token;
END;
$$ LANGUAGE plpgsql;

-- FUNCTION: validate_share_link
-- Check if a share link is valid (active, not expired)
CREATE OR REPLACE FUNCTION validate_share_link(p_token TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    is_valid BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM share_links
        WHERE token = p_token
        AND is_active = TRUE
        AND (expires_at IS NULL OR expires_at > NOW())
    ) INTO is_valid;

    RETURN is_valid;
END;
$$ LANGUAGE plpgsql;

-- 7. VIEWS (Common Queries)
-- =========================================================================

-- VIEW: collections_with_stories
-- Returns collections with aggregated story information
CREATE VIEW collections_with_stories AS
SELECT
    c.id,
    c.family_id,
    c.created_by,
    c.title,
    c.description,
    c.cover_image_url,
    c.order_index,
    c.created_at,
    c.updated_at,
    COUNT(cs.story_id) as story_count,
    -- Get cover image from first story if collection has no cover
    COALESCE(
        c.cover_image_url,
        (SELECT s.cover_image_url FROM collection_stories cs2
         JOIN stories s ON s.id = cs2.story_id
         WHERE cs2.collection_id = c.id
         ORDER BY cs2.order_index
         LIMIT 1)
    ) as effective_cover_image_url
FROM collections c
LEFT JOIN collection_stories cs ON cs.collection_id = c.id
GROUP BY c.id;

-- VIEW: active_share_links
-- Returns currently active share links with expiration status
CREATE VIEW active_share_links AS
SELECT
    sl.id,
    sl.created_by,
    sl.target_type,
    sl.target_id,
    sl.token,
    sl.permissions,
    sl.show_watermark,
    sl.watermark_text,
    sl.view_count,
    sl.last_accessed_at,
    sl.created_at,
    sl.expires_at,
    sl.is_active,
    NOT (sl.expires_at IS NULL OR sl.expires_at > NOW()) as is_expired,
    CASE
        WHEN sl.expires_at IS NULL THEN 'never'
        ELSE extract(epoch FROM (sl.expires_at - NOW()))::int
    END as expires_in_seconds
FROM share_links sl
WHERE sl.is_active = TRUE;

-- 8. GRANTS (Public Access for Share Links)
-- =========================================================================

-- Grant public access to validate and view share links (no auth required)
-- This function is used by the GET /api/public/s/:token endpoint
GRANT EXECUTE ON FUNCTION validate_share_link(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION increment_share_link_view_count(TEXT) TO anon;

-- COMMENTS (Documentation)
-- =========================================================================

COMMENT ON TABLE collections IS 'User-curated anthologies that bundle stories for export/sharing';
COMMENT ON TABLE collection_stories IS 'Join table linking stories to collections with custom ordering';
COMMENT ON TABLE share_links IS 'Public access tokens for sharing stories/collections without login requirement';
COMMENT ON COLUMN share_links.permissions IS 'JSONB: {view: bool, download: bool, comment: bool}';
COMMENT ON COLUMN share_links.show_watermark IS 'Add watermark to publicly viewed content';
COMMENT ON COLUMN share_links.token IS 'Public-facing token for share URL (e.g., storyrd.app/s/abc123xy)';
