// ============================================================================
// TRIGGER.DEV TASKS - Quote Generation
// ============================================================================
//
// Background task for generating quote cards from transcribed responses.
// Replaces the non-functional Cloudflare Queue system.
// ============================================================================

import { task } from "@trigger.dev/sdk";
import { createClient } from "@supabase/supabase-js";
import OpenAI from "openai";
import { EmbeddingsClient, quoteToEmbeddingText, formatEmbeddingForPostgres } from "../src/ai/embeddings";

// ============================================================================
// TYPES
// ============================================================================

interface GenerateQuotePayload {
  responseId: string;
  storyId: string | null;
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

function createBedrockClient() {
  return new OpenAI({
    baseURL: `https://bedrock-runtime.${awsRegion}.amazonaws.com/openai/v1`,
    apiKey: awsBedrockToken,
  });
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
 * Generate Quote Card Task
 *
 * Extracts a meaningful quote from a transcribed response and saves it as a shareable quote card.
 * Triggered when a response is transcribed or story is completed.
 */
export const generateQuoteTask = task({
  id: "generate-quote",
  description: "Generate a quote card from a transcribed response",
  retry: {
    maxAttempts: 3,
    factor: 2,
    minTimeoutInMs: 1000,
    maxTimeoutInMs: 10000,
  },
  run: async (payload: GenerateQuotePayload, { ctx }) => {
    console.log(`[Quote] Starting generation for response ${payload.responseId}`);

    const supabase = createSupabaseClient();
    const bedrock = createBedrockClient();

    // Step 1: Fetch response with profile
    const { data: response, error: fetchError } = await supabase
      .from("responses")
      .select(
        `
        id,
        transcription_text,
        story_id,
        profiles (
          id,
          full_name,
          role,
          family_id
        )
      `
      )
      .eq("id", payload.responseId)
      .single();

    if (fetchError || !response) {
      throw new Error(`Failed to fetch response: ${fetchError?.message || "Not found"}`);
    }

    const transcriptionText = response.transcription_text;
    if (!transcriptionText || transcriptionText.length < 50) {
      console.log(`[Quote] Text too short, skipping (${transcriptionText?.length || 0} chars)`);
      return {
        success: true,
        skipped: true,
        reason: "text_too_short",
        responseId: payload.responseId,
      };
    }

    // Step 2: Extract quote using LLM (AWS Bedrock)
    console.log(`[Quote] Extracting quote from ${transcriptionText.length} chars...`);

    try {
      const completion = await bedrock.chat.completions.create({
        model: "qwen.qwen3-next-80b-a3b",
        messages: [
          {
            role: "system",
            content: `You are an expert at extracting meaningful, shareable quotes from family conversations and stories.

Your task:
1. Analyze the given transcription
2. Extract the most meaningful, impactful, or touching quote
3. The quote should be:
   - 10-50 words long
   - Complete and coherent
   - Emotionally resonant
   - Something a family member would want to share

IMPORTANT:
- The quote must be EXACTLY from the transcription, no rewording
- If there's no good quote (too short, too generic), return an empty string
- Respond with valid JSON in this exact format:
{"quote": "the extracted quote here", "confidence": 0.85}

Confidence should be 0.0-1.0 based on how meaningful the quote is.`,
          },
          {
            role: "user",
            content: `Extract a meaningful quote from this family story:\n\n"${transcriptionText}"\n\nRespond with JSON only.`,
          },
        ],
        max_tokens: 300,
        temperature: 0.5,
        response_format: { type: "json_object" },
      });

      const message = completion.choices[0]?.message;
      if (!message?.content) {
        throw new Error("No response from Bedrock");
      }

      const jsonResponse = JSON.parse(message.content);
      const quote = jsonResponse.quote?.trim();
      const confidence = jsonResponse.confidence || 0;

      console.log(`[Quote] Extracted: "${quote.substring(0, 50)}..." (confidence: ${confidence})`);

      // Step 3: Only save high-confidence quotes
      if (confidence < 0.5 || !quote) {
        console.log(`[Quote] Low confidence (${confidence}) or empty quote, skipping`);
        return {
          success: true,
          skipped: true,
          reason: confidence < 0.5 ? "low_confidence" : "no_quote_found",
          confidence,
          responseId: payload.responseId,
        };
      }

      // Step 4: Create quote card
      const quoteCard = {
        quote_text: quote,
        author_name: response.profiles?.full_name || "Family Member",
        author_role: response.profiles?.role || "member",
        story_id: payload.storyId || response.story_id,
        theme: "classic",
        background_color: "#FFFFFF",
        text_color: "#000000",
        created_by: response.profiles?.id,
        family_id: response.profiles?.family_id,
      };

      const { data: createdQuote, error: insertError } = await supabase
        .from("quote_cards")
        .insert(quoteCard)
        .select()
        .single();

      if (insertError) {
        throw new Error(`Failed to create quote card: ${insertError.message}`);
      }

      console.log(`[Quote] ✅ Created quote card ${createdQuote.id}`);

      // Step 5: Generate and store embedding for semantic search
      try {
        const embeddings = createEmbeddingsClient();
        const embeddingText = quoteToEmbeddingText({
          quote_text: createdQuote.quote_text,
          author_name: createdQuote.author_name,
        });

        console.log(`[Quote] Generating embedding for semantic search...`);
        const result = await embeddings.embed(embeddingText);
        const pgVector = formatEmbeddingForPostgres(result.embedding);

        const { error: embeddingError } = await supabase
          .from("quote_cards")
          .update({ embedding: pgVector as any })
          .eq("id", createdQuote.id);

        if (embeddingError) {
          console.warn(`[Quote] Failed to store embedding:`, embeddingError);
        } else {
          console.log(`[Quote] ✅ Embedding stored successfully (${result.embedding.length} dims)`);
        }
      } catch (error) {
        console.warn(`[Quote] Failed to generate embedding:`, error);
        // Continue without embedding - search will use fallback
      }

      return {
        success: true,
        skipped: false,
        quoteId: createdQuote.id,
        quoteText: quote,
        quoteLength: quote.length,
        confidence,
        responseId: payload.responseId,
      };
    } catch (error) {
      console.error(`[Quote] ❌ LLM extraction failed:`, error);
      return {
        success: true,
        skipped: true,
        reason: "llm_failed",
        error: error instanceof Error ? error.message : String(error),
        responseId: payload.responseId,
      };
    }
  },
});
