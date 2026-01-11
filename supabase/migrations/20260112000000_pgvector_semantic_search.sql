-- =========================================================================
-- PGVECTOR SEMANTIC SEARCH
-- Store embeddings in database for instant similarity search
-- =========================================================================

-- 1. Enable pgvector extension (run this ONCE per database)
-- =========================================================================
CREATE EXTENSION IF NOT EXISTS vector;

-- 2. Add embedding column to stories table
-- =========================================================================
ALTER TABLE stories ADD COLUMN embedding vector(1536);  -- 1536 dims for text-embedding-3-small

-- Create index for cosine similarity search (IVFFLAT is faster than HNSW for small datasets)
CREATE INDEX ON stories USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- 3. Add embedding column to quote_cards table
-- =========================================================================
ALTER TABLE quote_cards ADD COLUMN embedding vector(1536);

CREATE INDEX ON quote_cards USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- 4. RPC function for semantic story search using pgvector
-- =========================================================================
DROP FUNCTION IF EXISTS semantic_search_stories(UUID, TEXT, INTEGER);

CREATE OR REPLACE FUNCTION semantic_search_stories(
    p_family_id UUID,
    p_query_embedding vector(1536),
    p_limit INTEGER DEFAULT 10,
    p_min_similarity FLOAT DEFAULT 0.3
)
RETURNS TABLE (
    id UUID,
    title TEXT,
    summary_text TEXT,
    cover_image_url TEXT,
    voice_count INTEGER,
    similarity FLOAT,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.id,
        s.title,
        s.summary_text,
        s.cover_image_url,
        s.voice_count,
        1 - (s.embedding <=> p_query_embedding) AS similarity,  -- Convert distance to similarity
        s.created_at
    FROM stories s
    WHERE s.family_id = p_family_id
      AND s.is_completed = true
      AND s.embedding IS NOT NULL
      AND (1 - (s.embedding <=> p_query_embedding)) >= p_min_similarity
    ORDER BY s.embedding <=> p_query_embedding  -- Order by cosine distance
    LIMIT p_limit;
END;
$$;

-- 5. RPC function for semantic quote search using pgvector
-- =========================================================================
DROP FUNCTION IF EXISTS semantic_search_quotes(UUID, TEXT, INTEGER);

CREATE OR REPLACE FUNCTION semantic_search_quotes(
    p_family_id UUID,
    p_query_embedding vector(1536),
    p_limit INTEGER DEFAULT 10,
    p_min_similarity FLOAT DEFAULT 0.3
)
RETURNS TABLE (
    id UUID,
    quote_text TEXT,
    author_name TEXT,
    author_role VARCHAR(20),
    story_id UUID,
    similarity FLOAT,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        q.id,
        q.quote_text,
        q.author_name,
        q.author_role,
        q.story_id,
        1 - (q.embedding <=> p_query_embedding) AS similarity,
        q.created_at
    FROM quote_cards q
    WHERE q.family_id = p_family_id
      AND q.embedding IS NOT NULL
      AND (1 - (q.embedding <=> p_query_embedding)) >= p_min_similarity
    ORDER BY q.embedding <=> p_query_embedding
    LIMIT p_limit;
END;
$$;

-- 6. Combined search function (returns both stories and quotes)
-- =========================================================================
DROP FUNCTION IF EXISTS combined_semantic_search(UUID, TEXT, INTEGER, FLOAT);

CREATE OR REPLACE FUNCTION combined_semantic_search(
    p_family_id UUID,
    p_query_embedding vector(1536),
    p_limit INTEGER DEFAULT 10,
    p_min_similarity FLOAT DEFAULT 0.3
)
RETURNS TABLE (
    id UUID,
    type VARCHAR(10),
    title TEXT,
    content TEXT,
    author_name TEXT,
    author_role VARCHAR(20),
    story_id UUID,
    similarity FLOAT,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_story_limit INTEGER;
    v_quote_limit INTEGER;
BEGIN
    -- Split limit between stories and quotes
    v_story_limit := p_limit / 2;
    v_quote_limit := p_limit - v_story_limit;

    -- Return stories
    RETURN QUERY
    SELECT
        s.id,
        'story'::VARCHAR(10) AS type,
        s.title AS title,
        s.summary_text AS content,
        NULL::TEXT AS author_name,
        NULL::VARCHAR(20) AS author_role,
        NULL::UUID AS story_id,
        (1 - (s.embedding <=> p_query_embedding)) AS similarity,
        s.created_at
    FROM stories s
    WHERE s.family_id = p_family_id
      AND s.is_completed = true
      AND s.embedding IS NOT NULL
      AND (1 - (s.embedding <=> p_query_embedding)) >= p_min_similarity
    ORDER BY s.embedding <=> p_query_embedding
    LIMIT v_story_limit;

    -- Append quotes
    RETURN QUERY
    SELECT
        q.id,
        'quote'::VARCHAR(10) AS type,
        LEFT(q.quote_text, 100) || '...' AS title,
        q.quote_text AS content,
        q.author_name,
        q.author_role,
        q.story_id,
        (1 - (q.embedding <=> p_query_embedding)) AS similarity,
        q.created_at
    FROM quote_cards q
    WHERE q.family_id = p_family_id
      AND q.embedding IS NOT NULL
      AND (1 - (q.embedding <=> p_query_embedding)) >= p_min_similarity
    ORDER BY q.embedding <=> p_query_embedding
    LIMIT v_quote_limit;
END;
$$;

-- 7. Helper function to update story embedding
-- =========================================================================
DROP FUNCTION IF EXISTS update_story_embedding(UUID);

CREATE OR REPLACE FUNCTION update_story_embedding(p_story_id UUID)
RETURNS void AS $$
BEGIN
    -- Will be called from application layer after generating embedding
    RAISE NOTICE 'Story % embedding update triggered', p_story_id;
END;
$$ LANGUAGE plpgsql;

-- 8. Helper function to update quote embedding
-- =========================================================================
DROP FUNCTION IF EXISTS update_quote_embedding(UUID);

CREATE OR REPLACE FUNCTION update_quote_embedding(p_quote_id UUID)
RETURNS void AS $$
BEGIN
    RAISE NOTICE 'Quote % embedding update triggered', p_quote_id;
END;
$$ LANGUAGE plpgsql;

-- 9. Grant permissions for RLS (embeddings follow existing policies)
-- =========================================================================
-- Stories: existing RLS policies already cover embedding column
-- Quote_cards: existing RLS policies already cover embedding column

-- 10. Update existing RLS policies to include embedding column access
-- =========================================================================
-- Note: RLS policies apply to the entire table, including new columns
-- The existing "Users can view family stories" policy already covers this

-- 11. Create function to backfill embeddings for existing stories (optional)
-- =========================================================================
DROP FUNCTION IF EXISTS backfill_story_embeddings();

CREATE OR REPLACE FUNCTION backfill_story_embeddings()
RETURNS TABLE (story_id UUID, status TEXT) AS $$
DECLARE
    v_story RECORD;
BEGIN
    FOR v_story IN
        SELECT id, title, summary_text FROM stories
        WHERE embedding IS NULL AND is_completed = true
    LOOP
        -- Note: Actual embedding generation happens in application layer
        -- This function is a placeholder for monitoring
        story_id := v_story.id;
        status := 'pending_embedding';
        RETURN NEXT;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION semantic_search_stories IS 'Search stories by semantic similarity using pgvector cosine distance';
COMMENT ON FUNCTION semantic_search_quotes IS 'Search quotes by semantic similarity using pgvector cosine distance';
COMMENT ON FUNCTION combined_semantic_search IS 'Search both stories and quotes, returning combined results';
