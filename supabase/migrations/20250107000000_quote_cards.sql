-- =========================================================================
-- STORYRD - QUOTE CARDS FEATURE
-- Adds: quote_cards table for shareable wisdom quotes
-- =========================================================================

-- 1. QUOTE CARDS - Shareable quote images from stories
-- =========================================================================
CREATE TABLE quote_cards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- The quote content
    quote_text TEXT NOT NULL,
    author_name TEXT NOT NULL,
    author_role VARCHAR(50),           -- 'grandma', 'grandpa', 'uncle', 'mom', 'dad', etc.
    story_id UUID REFERENCES stories(id) ON DELETE CASCADE,
    
    -- Visual styling
    theme VARCHAR(20) DEFAULT 'classic',  -- 'classic', 'modern', 'bold', 'minimal'
    background_color VARCHAR(20) DEFAULT '#FFFFFF',
    text_color VARCHAR(20) DEFAULT '#000000',
    
    -- Generated image URL (stored in R2)
    image_url TEXT,
    
    -- Usage stats
    views_count INT DEFAULT 0,
    shares_count INT DEFAULT 0,
    saves_count INT DEFAULT 0,
    
    -- Metadata
    created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    family_id UUID REFERENCES families(id) ON DELETE CASCADE NOT NULL,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. ENABLE RLS ON QUOTE_CARDS
-- =========================================================================
ALTER TABLE quote_cards ENABLE ROW LEVEL SECURITY;

-- Users can view quote cards from their family
CREATE POLICY "Users can view family quote cards" ON quote_cards
    FOR SELECT USING (
        family_id IN (SELECT family_id FROM profiles WHERE auth_user_id = auth.uid())
    );

-- Users can create quote cards for their family's stories
CREATE POLICY "Users can create quote cards" ON quote_cards
    FOR INSERT WITH CHECK (
        family_id IN (SELECT family_id FROM profiles WHERE auth_user_id = auth.uid())
    );

-- Users can update their own quote cards
CREATE POLICY "Users can update own quote cards" ON quote_cards
    FOR UPDATE USING (
        created_by IN (SELECT id FROM profiles WHERE auth_user_id = auth.uid())
    );

-- Users can delete their own quote cards
CREATE POLICY "Users can delete own quote cards" ON quote_cards
    FOR DELETE USING (
        created_by IN (SELECT id FROM profiles WHERE auth_user_id = auth.uid())
    );

-- 3. INDEXES FOR PERFORMANCE
-- =========================================================================
CREATE INDEX idx_quote_cards_family ON quote_cards(family_id);
CREATE INDEX idx_quote_cards_story ON quote_cards(story_id);
CREATE INDEX idx_quote_cards_created ON quote_cards(created_at);
CREATE INDEX idx_quote_cards_author ON quote_cards(author_role);

-- 4. HELPER FUNCTIONS
-- =========================================================================

-- FUNCTION: Get popular quote cards for a family
CREATE OR REPLACE FUNCTION get_popular_quote_cards(
    p_family_id UUID,
    p_limit INT DEFAULT 10
)
RETURNS TABLE (
    id UUID,
    quote_text TEXT,
    author_name TEXT,
    author_role VARCHAR(50),
    image_url TEXT,
    theme VARCHAR(20),
    views_count INT,
    shares_count INT,
    saves_count INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        qc.id,
        qc.quote_text,
        qc.author_name,
        qc.author_role,
        qc.image_url,
        qc.theme,
        qc.views_count,
        qc.shares_count,
        qc.saves_count
    FROM quote_cards qc
    WHERE qc.family_id = p_family_id
    ORDER BY (qc.views_count + qc.shares_count * 2 + qc.saves_count * 3) DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- FUNCTION: Increment view count
CREATE OR REPLACE FUNCTION increment_quote_card_views(p_quote_card_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE quote_cards 
    SET views_count = views_count + 1, updated_at = NOW()
    WHERE id = p_quote_card_id;
END;
$$ LANGUAGE plpgsql;

-- FUNCTION: Increment share count
CREATE OR REPLACE FUNCTION increment_quote_card_shares(p_quote_card_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE quote_cards 
    SET shares_count = shares_count + 1, updated_at = NOW()
    WHERE id = p_quote_card_id;
END;
$$ LANGUAGE plpgsql;

-- FUNCTION: Increment save count
CREATE OR REPLACE FUNCTION increment_quote_card_saves(p_quote_card_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE quote_cards 
    SET saves_count = saves_count + 1, updated_at = NOW()
    WHERE id = p_quote_card_id;
END;
$$ LANGUAGE plpgsql;

