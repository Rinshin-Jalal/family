-- ============================================================================
-- ADD TTS CACHING TO RESPONSES
-- ============================================================================
--
-- This migration adds fields to cache TTS-generated audio for responses
-- that don't have original audio recordings (text, images, PDFs, etc.)
--
-- This allows podcasts to include ALL response types, not just audio.
-- ============================================================================

-- Add TTS audio caching fields to responses table
ALTER TABLE responses
  ADD COLUMN IF NOT EXISTS tts_audio_key TEXT,
  ADD COLUMN IF NOT EXISTS tts_generated_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS tts_duration_seconds DECIMAL(10, 2),
  ADD COLUMN IF NOT EXISTS tts_voice_id TEXT;

-- Create index on tts_audio_key for faster lookups
CREATE INDEX IF NOT EXISTS idx_responses_tts_audio_key ON responses(tts_audio_key) WHERE tts_audio_key IS NOT NULL;

-- Add comment for documentation
COMMENT ON COLUMN responses.tts_audio_key IS 'R2 storage key for TTS-generated audio (used for non-audio responses)';
COMMENT ON COLUMN responses.tts_generated_at IS 'Timestamp when TTS audio was generated';
COMMENT ON COLUMN responses.tts_duration_seconds IS 'Duration of TTS-generated audio in seconds';
COMMENT ON COLUMN responses.tts_voice_id IS 'Cartesia voice ID used for TTS generation';
