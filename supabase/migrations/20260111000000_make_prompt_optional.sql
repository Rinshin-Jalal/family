-- Make prompt_id optional in responses table
-- This allows AI-generated prompts to be created after transcription

-- Drop the foreign key constraint first
ALTER TABLE responses DROP CONSTRAINT responses_prompt_id_fkey;

-- Make the column nullable
ALTER TABLE responses ALTER COLUMN prompt_id DROP NOT NULL;

-- Re-add the foreign key constraint (now nullable)
ALTER TABLE responses ADD CONSTRAINT responses_prompt_id_fkey
  FOREIGN KEY (prompt_id) REFERENCES prompts(id) ON DELETE SET NULL;

-- Add comment explaining the new behavior
COMMENT ON COLUMN responses.prompt_id IS 'Optional: Links to the prompt that generated this response. If null, a prompt is auto-generated after transcription.';
