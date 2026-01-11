// ============================================================================
// TRIGGER.DEV TASKS - Response Embeddings
// ============================================================================
//
// Generates vector embeddings for individual responses to enable semantic search.
// Runs after transcription is complete.
// ============================================================================

import { task } from "@trigger.dev/sdk";
import { createClient } from "@supabase/supabase-js";
import { EmbeddingsClient, formatEmbeddingForPostgres } from "../src/ai/embeddings";

// ============================================================================
// TYPES
// ============================================================================

interface EmbedResponsePayload {
  responseId: string;
  triggeredBy: "response.transcribed" | "story.completed" | "manual";
}

// ============================================================================
// CLIENTS
// ============================================================================

// Environment variables (will be loaded by trigger.dev)
const supabaseUrl = process.env.SUPABASE_URL!;
const supabaseKey = process.env.SUPABASE_KEY!;
const awsBedrockToken = process.env.AWS_BEARER_TOKEN_BEDROCK!;
const awsRegion = process.env.AWS_REGION || "us-east-1";

function createSupabaseClient() {
  return createClient(supabaseUrl, supabaseKey);
}

function createEmbeddingsClient(): EmbeddingsClient {
  return new EmbeddingsClient({
    openaiApiKey: awsBedrockToken,
    bedrockRegion: awsRegion,
  });
}

// ============================================================================
// TASK DEFINITION
// ============================================================================

/**
 * Generate Embedding for Response
 *
 * Creates a 1024-dimensional vector embedding from the response's transcription
 * for semantic search capabilities.
 *
 * Triggered:
 * - After transcription completes (response.transcribed)
 * - After story completion (story.completed) - backfill existing responses
 * - Manually via API for existing responses
 */
export const embedResponseTask = task({
  id: "embed-response",
  description: "Generate vector embedding for a response's transcription text",
  retry: {
    maxAttempts: 3,
    factor: 2,
    minTimeoutInMs: 1000,
    maxTimeoutInMs: 10000,
  },
  run: async (payload: EmbedResponsePayload, { ctx }) => {
    console.log(`[ResponseEmbed] Starting embedding generation for response ${payload.responseId}`);

    const supabase = createSupabaseClient();
    const embeddings = createEmbeddingsClient();

    // Step 1: Fetch response with transcription
    const { data: response, error: fetchError } = await supabase
      .from("responses")
      .select(`
        id,
        transcription_text,
        story_id,
        user_id,
        profiles(full_name, role, family_id)
      `)
      .eq("id", payload.responseId)
      .single();

    if (fetchError || !response) {
      throw new Error(`Failed to fetch response: ${fetchError?.message || "Not found"}`);
    }

    const transcriptionText = response.transcription_text;
    if (!transcriptionText || transcriptionText.length < 10) {
      console.log(`[ResponseEmbed] Text too short or empty (${transcriptionText?.length || 0} chars), skipping`);
      return {
        success: true,
        skipped: true,
        reason: "text_too_short",
        responseId: payload.responseId,
      };
    }

    console.log(`[ResponseEmbed] Generating embedding for ${transcriptionText.length} chars transcription`);

    // Step 2: Generate embedding using AWS Bedrock Titan
    try {
      const result = await embeddings.embed(transcriptionText);
      const pgVector = formatEmbeddingForPostgres(result.embedding);

      // Step 3: Store embedding in responses table
      const { error: updateError } = await supabase
        .from("responses")
        .update({ embedding: pgVector as any })
        .eq("id", payload.responseId);

      if (updateError) {
        console.warn(`[ResponseEmbed] Failed to store embedding:`, updateError);
        // Continue - search will use fallback
      } else {
        console.log(`[ResponseEmbed] ✅ Embedding stored successfully (${result.embedding.length} dims) for response ${payload.responseId}`);
      }

      return {
        success: true,
        skipped: false,
        responseId: payload.responseId,
        storyId: response.story_id,
        authorName: response.profiles?.full_name || "Unknown",
        embeddingDims: result.embedding.length,
        textLength: transcriptionText.length,
      };
    } catch (error) {
      console.error(`[ResponseEmbed] ❌ Failed to generate embedding:`, error);
      return {
        success: true,
        skipped: true,
        reason: "embedding_failed",
        error: error instanceof Error ? error.message : String(error),
        responseId: payload.responseId,
      };
    }
  },
});
