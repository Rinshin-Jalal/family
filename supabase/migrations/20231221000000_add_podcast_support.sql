-- ============================================================================
-- PODCAST SUPPORT MIGRATION
-- ============================================================================
--
-- Adds support for AI-generated audio podcasts that weave together
-- family voice recordings with smart transitions and background music.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Add podcast fields to stories table
-- ----------------------------------------------------------------------------

ALTER TABLE stories
ADD COLUMN podcast_url TEXT,
ADD COLUMN podcast_duration_seconds INTEGER,
ADD COLUMN is_podcast_ready BOOLEAN DEFAULT FALSE,
ADD COLUMN podcast_generated_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN podcast_version INTEGER DEFAULT 0,
ADD COLUMN podcast_status VARCHAR(20) DEFAULT 'pending'
CHECK (podcast_status IN ('pending', 'generating', 'ready', 'failed', 'regenerating'));

-- Add index for querying stories by podcast status
CREATE INDEX idx_stories_podcast_status ON stories(podcast_status)
WHERE is_podcast_ready = FALSE;

-- Add index for querying ready podcasts
CREATE INDEX idx_stories_podcast_ready ON stories(is_podcast_ready, podcast_generated_at DESC)
WHERE is_podcast_ready = TRUE;

-- ----------------------------------------------------------------------------
-- Add audio processing status to responses table
-- ----------------------------------------------------------------------------

ALTER TABLE responses
ADD COLUMN audio_processed_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN audio_key VARCHAR(255);  -- R2 storage key for the audio file

-- Add comment for documentation
COMMENT ON COLUMN stories.podcast_url IS 'R2 URL of the generated podcast audio file';
COMMENT ON COLUMN stories.podcast_duration_seconds IS 'Length of the podcast in seconds';
COMMENT ON COLUMN stories.is_podcast_ready IS 'TRUE when podcast is ready for playback';
COMMENT ON COLUMN stories.podcast_generated_at IS 'Timestamp when podcast was generated';
COMMENT ON COLUMN stories.podcast_version IS 'Incremented each time podcast is regenerated';
COMMENT ON COLUMN stories.podcast_status IS 'Current podcast generation status: pending, generating, ready, failed, regenerating';
COMMENT ON COLUMN responses.audio_processed_at IS 'Timestamp when this audio was processed into a podcast';
COMMENT ON COLUMN responses.audio_key IS 'R2 storage key for the original audio file';

-- ----------------------------------------------------------------------------
-- Trigger to set initial podcast status
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION set_initial_podcast_status()
RETURNS TRIGGER AS $$
BEGIN
  -- Set default podcast status when story is created
  NEW.podcast_status := 'pending';
  NEW.podcast_version := 0;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_initial_podcast_status
BEFORE INSERT ON stories
FOR EACH ROW
EXECUTE FUNCTION set_initial_podcast_status();

-- ----------------------------------------------------------------------------
-- Update existing stories to have correct initial state
-- ----------------------------------------------------------------------------

UPDATE stories
SET podcast_status = 'pending',
    podcast_version = 0
WHERE podcast_status IS NULL;
