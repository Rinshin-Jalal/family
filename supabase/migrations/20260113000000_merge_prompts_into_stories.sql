-- ============================================================================
-- MERGE PROMPTS INTO STORIES
-- ============================================================================
-- This migration:
-- 1. Adds prompt fields to stories table
-- 2. Migrates existing prompt data to stories
-- 3. Removes prompt_id foreign keys
-- 4. Drops the prompts table
-- ============================================================================

-- STEP 1: Add prompt fields to stories table
ALTER TABLE stories
  ADD COLUMN prompt_text TEXT,
  ADD COLUMN prompt_category VARCHAR(50),
  ADD COLUMN prompt_is_custom BOOLEAN DEFAULT FALSE,
  ADD COLUMN prompt_scheduled_for TIMESTAMPTZ;

-- Add comments for documentation
COMMENT ON COLUMN stories.prompt_text IS 'The question/prompt that generated this story';
COMMENT ON COLUMN stories.prompt_category IS 'Category of the prompt (e.g., childhood, holidays, funny)';
COMMENT ON COLUMN stories.prompt_is_custom IS 'Whether this was a custom user-created prompt';
COMMENT ON COLUMN stories.prompt_scheduled_for IS 'When the prompt was scheduled for (if automated)';

-- STEP 2: Migrate existing data from prompts to stories
UPDATE stories s
SET
  prompt_text = p.text,
  prompt_category = p.category,
  prompt_is_custom = p.is_custom,
  prompt_scheduled_for = p.scheduled_for
FROM prompts p
WHERE s.prompt_id = p.id;

-- STEP 3: Drop view that depends on prompt_id
DROP VIEW IF EXISTS home_feed;

-- STEP 4: Remove prompt_id foreign key from stories
ALTER TABLE stories DROP CONSTRAINT IF EXISTS stories_prompt_id_fkey;
ALTER TABLE stories DROP COLUMN IF EXISTS prompt_id;

-- STEP 4: Remove prompt_id foreign key from responses
ALTER TABLE responses DROP CONSTRAINT IF EXISTS responses_prompt_id_fkey;
ALTER TABLE responses DROP COLUMN IF EXISTS prompt_id;

-- STEP 5: Drop indexes related to prompts
DROP INDEX IF EXISTS idx_stories_prompt;
DROP INDEX IF EXISTS idx_responses_prompt;

-- STEP 6: Drop RLS policies for prompts
DROP POLICY IF EXISTS "Users can view family prompts" ON prompts;

-- STEP 7: Drop the prompts table
DROP TABLE IF EXISTS prompts CASCADE;

-- STEP 8: Update home_feed view to remove prompts JOIN
CREATE OR REPLACE VIEW home_feed AS
SELECT
  s.id as story_id,
  s.title,
  s.cover_image_url,
  s.created_at,
  s.voice_count,
  s.prompt_text as prompt_text,
  s.prompt_category as prompt_category
FROM stories s
ORDER BY s.created_at DESC;

-- STEP 9: Add indexes for new prompt fields in stories
CREATE INDEX idx_stories_prompt_category ON stories(prompt_category);
CREATE INDEX idx_stories_prompt_scheduled ON stories(prompt_scheduled_for) WHERE prompt_scheduled_for IS NOT NULL;
