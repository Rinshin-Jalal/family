// ============================================================================
// TRIGGER.DEV TASKS - Response Transcription
// ============================================================================
//
// Background task for transcribing audio responses using Cartesia.
// Triggers quote generation and wisdom tagging when complete.
// ============================================================================

import { task } from "@trigger.dev/sdk";
import { createCartesiaClient } from "../src/ai/cartesia";
import { createClient } from "@supabase/supabase-js";

// ============================================================================
// TYPES
// ============================================================================

interface TranscribeResponsePayload {
  responseId: string;
  audioKey: string;
  audioUrl: string;
  userId: string;
  familyId: string;
}

// ============================================================================
// TASK DEFINITION
// ============================================================================

/**
 * Transcribe Response Task
 *
 * Downloads audio from R2, transcribes using Cartesia,
 * and triggers downstream tasks (quote generation, wisdom tagging).
 */
export const transcribeResponseTask = task({
  id: "transcribe-response",
  description: "Transcribe audio response using Cartesia and trigger quote/wisdom generation",
  retry: {
    maxAttempts: 3,
    factor: 2,
    minTimeoutInMs: 1000,
    maxTimeoutInMs: 10000,
  },
  run: async (payload: TranscribeResponsePayload, { ctx }) => {
    console.log(`[Transcription] Starting for response ${payload.responseId}`);

    // Initialize Supabase client
    const supabase = createClient(
      process.env.SUPABASE_URL!,
      process.env.SUPABASE_KEY!
    );

    // Step 1: Fetch response
    const { data: response, error: fetchError } = await supabase
      .from("responses")
      .select("id, story_id, prompt_id, media_url")
      .eq("id", payload.responseId)
      .single();

    if (fetchError || !response) {
      throw new Error(`Failed to fetch response: ${fetchError?.message || "Not found"}`);
    }

    console.log(`[Transcription] Found response, story_id: ${response.story_id}`);

    // Step 2: Download audio from R2
    console.log(`[Transcription] Downloading audio from R2: ${payload.audioKey}`);

    // For now, we'll use the audio URL directly since R2 is accessible via HTTP
    // In production, you'd use the R2 bucket binding
    const audioResponse = await fetch(payload.audioUrl);
    if (!audioResponse.ok) {
      throw new Error(`Failed to download audio: ${audioResponse.statusText}`);
    }

    const audioBuffer = await audioResponse.arrayBuffer();
    console.log(`[Transcription] Downloaded ${audioBuffer.byteLength} bytes`);

    // Step 3: Transcribe using Cartesia
    console.log(`[Transcription] Sending to Cartesia for transcription...`);
    const cartesia = createCartesiaClient({
      apiKey: process.env.CARTESIA_API_KEY!,
    });

    const transcription = await cartesia.transcribeAudio(audioBuffer);

    console.log(
      `[Transcription] ✅ Transcribed ${transcription.text.length} chars, ${transcription.duration_seconds}s`
    );

    // Step 4: Update response with transcription
    const { error: updateError } = await supabase
      .from("responses")
      .update({
        transcription_text: transcription.text,
        duration_seconds: transcription.duration_seconds,
        processing_status: "completed",
        audio_processed_at: new Date().toISOString(),
      })
      .eq("id", payload.responseId);

    if (updateError) {
      throw new Error(`Failed to update response: ${updateError.message}`);
    }

    // ========================================================================
    // KEY LOGIC: Handle story creation vs. existing story
    // ========================================================================

    if (!response.story_id) {
      // NO STORY_ID: Need to create story first, then quote + response-level tasks
      console.log(`[Transcription] No story_id, triggering story creation flow...`);

      // This will: create prompt → create story → trigger quote
      // NEW: Response-level tasks (embedding + wisdom tags) are now triggered AFTER story creation
      const { processResponseTask } = await import("./process-response-task");
      const processHandle = await processResponseTask.trigger({
        responseId: payload.responseId,
        transcriptionText: transcription.text,
        familyId: payload.familyId,
        userId: payload.userId,
      });

      console.log(`[Transcription] ✅ Story creation flow triggered: ${processHandle.id}`);

      return {
        success: true,
        responseId: payload.responseId,
        textLength: transcription.text.length,
        duration: transcription.duration_seconds,
        storyCreationTriggered: true,
      };
    }

    // HAS STORY_ID: Add to existing story, trigger response-level processes
    console.log(`[Transcription] Has story_id ${response.story_id}, triggering response-level processes...`);

    const tasksTriggered: string[] = [];

    // Process 1: Quote generation (if text is long enough)
    if (transcription.text.length >= 50) {
      console.log(`[Transcription] Triggering quote generation...`);

      const { generateQuoteTask } = await import("./quote-task");
      const quoteHandle = await generateQuoteTask.trigger({
        responseId: payload.responseId,
        storyId: response.story_id,
        triggeredBy: "response.transcribed",
      });

      console.log(`[Transcription] ✅ Quote generation triggered: ${quoteHandle.id}`);
      tasksTriggered.push("quote");
    } else {
      console.log(`[Transcription] Text too short (${transcription.text.length} chars), skipping quote`);
    }

    // Process 2: Generate embedding for this response (NEW - response-level)
    // This enables semantic search on individual responses
    console.log(`[Transcription] Triggering response embedding...`);

    const { embedResponseTask } = await import("./response-embed-task");
    const embedHandle = await embedResponseTask.trigger({
      responseId: payload.responseId,
      triggeredBy: "response.transcribed",
    });

    console.log(`[Transcription] ✅ Response embedding triggered: ${embedHandle.id}`);
    tasksTriggered.push("response_embedding");

    // Process 3: Generate wisdom tags for this response (NEW - response-level)
    // This enables wisdom search on individual responses
    console.log(`[Transcription] Triggering response wisdom tagging...`);

    const { tagResponseWisdomTask } = await import("./response-tag-task");
    const wisdomHandle = await tagResponseWisdomTask.trigger({
      responseId: payload.responseId,
      triggeredBy: "response.transcribed",
    });

    console.log(`[Transcription] ✅ Response wisdom tagging triggered: ${wisdomHandle.id}`);
    tasksTriggered.push("response_wisdom");

    return {
      success: true,
      responseId: payload.responseId,
      storyId: response.story_id,
      textLength: transcription.text.length,
      duration: transcription.duration_seconds,
      tasksTriggered,
      note: "Response-level embedding and wisdom tagging triggered",
    };
  },
});
