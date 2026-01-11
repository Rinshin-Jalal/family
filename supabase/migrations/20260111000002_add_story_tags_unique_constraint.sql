-- =========================================================================
-- ADD UNIQUE CONSTRAINT TO STORY_TAGS
-- ============================================================================
--
-- Fixes: "there is no unique or exclusion constraint matching the ON CONFLICT specification"
-- Adds unique constraint on story_id to enable upsert operations
-- ============================================================================

-- Remove any existing duplicate story_tags (keep first occurrence)
WITH ranked_tags AS (
  SELECT id,
         ROW_NUMBER() OVER (PARTITION BY story_id ORDER BY created_at) as rn
  FROM story_tags
)
DELETE FROM story_tags
WHERE id IN (
  SELECT id FROM ranked_tags WHERE rn > 1
);

-- Add unique constraint on story_id
ALTER TABLE story_tags
  ADD CONSTRAINT story_tags_story_id_key UNIQUE (story_id);

-- Add comment for documentation
COMMENT ON CONSTRAINT story_tags_story_id_key ON story_tags IS 'Ensures one tag record per story for upsert operations';
