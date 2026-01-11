-- =========================================================================
-- FIX EMBEDDING DIMENSIONS FOR AWS TITAN v2
-- ============================================================================
--
-- Changes vector dimensions from 1536 to 1024 to match amazon.titan-embed-text-v2
-- The original migration used text-embedding-3-small (1536 dims) but that model
-- is not available in AWS Bedrock.
--
-- ============================================================================

-- Drop existing indexes
DROP INDEX IF EXISTS stories_embedding_idx;
DROP INDEX IF EXISTS quote_cards_embedding_idx;

-- Drop existing functions that reference vector(1536)
DROP FUNCTION IF EXISTS semantic_search_stories(UUID, vector(1536), INTEGER, FLOAT);
DROP FUNCTION IF EXISTS semantic_search_quotes(UUID, vector(1536), INTEGER, FLOAT);
DROP FUNCTION IF EXISTS combined_semantic_search(UUID, vector(1536), INTEGER, FLOAT);

-- Alter stories table (recreate column)
ALTER TABLE stories DROP COLUMN IF EXISTS embedding;
ALTER TABLE stories ADD COLUMN embedding vector(1024);

-- Alter quote_cards table (recreate column)
ALTER TABLE quote_cards DROP COLUMN IF EXISTS embedding;
ALTER TABLE quote_cards ADD COLUMN embedding vector(1024);

-- Recreate indexes with correct dimensions
CREATE INDEX stories_embedding_idx ON stories USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
CREATE INDEX quote_cards_embedding_idx ON quote_cards USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- Recreate functions with vector(1024)
DROP FUNCTION IF EXISTS semantic_search_stories;

CREATE OR REPLACE FUNCTION semantic_search_stories(
    p_family_id UUID,
    p_query_embedding vector(1024),
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
LANGUAGE SQL
AS $$
    SELECT
        s.id,
        s.title,
        s.summary_text,
        s.cover_image_url,
        s.voice_count,
        1 - (s.embedding <=> p_query_embedding) AS similarity,
        s.created_at
    FROM stories s
    WHERE s.family_id = p_family_id
      AND s.embedding IS NOT NULL
      AND (1 - (s.embedding <=> p_query_embedding)) >= p_min_similarity
    ORDER BY s.embedding <=> p_query_embedding
    LIMIT p_limit;
$$;

DROP FUNCTION IF EXISTS semantic_search_quotes;

CREATE OR REPLACE FUNCTION semantic_search_quotes(
    p_family_id UUID,
    p_query_embedding vector(1024),
    p_limit INTEGER DEFAULT 10,
    p_min_similarity FLOAT DEFAULT 0.3
)
RETURNS TABLE (
    id UUID,
    quote_text TEXT,
    author_name TEXT,
    author_role TEXT,
    story_id UUID,
    similarity FLOAT,
    created_at TIMESTAMPTZ
)
LANGUAGE SQL
AS $$
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
$$;

DROP FUNCTION IF EXISTS combined_semantic_search;

CREATE OR REPLACE FUNCTION combined_semantic_search(
    p_family_id UUID,
    p_query_embedding vector(1024),
    p_limit INTEGER DEFAULT 10,
    p_min_similarity FLOAT DEFAULT 0.3
)
RETURNS TABLE (
    id UUID,
    type TEXT,
    title TEXT,
    content TEXT,
    author_name TEXT,
    author_role TEXT,
    story_id UUID,
    similarity FLOAT,
    created_at TIMESTAMPTZ
)
LANGUAGE SQL
AS $$
    SELECT
        s.id,
        'story'::TEXT as type,
        s.title,
        s.summary_text as content,
        NULL::TEXT as author_name,
        NULL::TEXT as author_role,
        NULL::UUID as story_id,
        (1 - (s.embedding <=> p_query_embedding)) AS similarity,
        s.created_at
    FROM stories s
    WHERE s.family_id = p_family_id
      AND s.embedding IS NOT NULL
      AND (1 - (s.embedding <=> p_query_embedding)) >= p_min_similarity

    UNION ALL

    SELECT
        q.id,
        'quote'::TEXT as type,
        q.quote_text as title,
        q.quote_text as content,
        q.author_name,
        q.author_role,
        q.story_id,
        (1 - (q.embedding <=> p_query_embedding)) AS similarity,
        q.created_at
    FROM quote_cards q
    WHERE q.family_id = p_family_id
      AND q.embedding IS NOT NULL
      AND (1 - (q.embedding <=> p_query_embedding)) >= p_min_similarity

    ORDER BY similarity DESC
    LIMIT p_limit;
$$;

-- Add comments
COMMENT ON COLUMN stories.embedding IS 'Vector embedding (1024 dims) using amazon.titan-embed-text-v2 for semantic search';
COMMENT ON COLUMN quote_cards.embedding IS 'Vector embedding (1024 dims) using amazon.titan-embed-text-v2 for semantic search';
COMMENT ON FUNCTION semantic_search_stories IS 'Search stories by semantic similarity using pgvector cosine distance (1024 dims)';
COMMENT ON FUNCTION semantic_search_quotes IS 'Search quotes by semantic similarity using pgvector cosine distance (1024 dims)';
COMMENT ON FUNCTION combined_semantic_search IS 'Search both stories and quotes, returning combined results (1024 dims)';
