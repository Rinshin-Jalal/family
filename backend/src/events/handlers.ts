// ============================================================================
// EVENT HANDLERS - Process events from the queue
// ============================================================================
//
// Each handler is responsible for:
// 1. Processing a single event type
// 2. Performing business logic (AI, DB operations, etc.)
// 3. Returning success/failure for retry logic
//
// Handlers are pure functions - easy to test and reason about.
// ============================================================================

import type { EventHandlerResult, EventEnvelope } from './types'
import { createQwenTurboClient } from '../ai/llm'
import { createCartesiaClient } from '../ai/cartesia'
import type { QwenTurboClient } from '../ai/llm'
import type { CartesiaClient } from '../ai/cartesia'

// ----------------------------------------------------------------------------
// DEPENDENCIES - Supabase client and AI services
// ----------------------------------------------------------------------------

export interface HandlerContext {
  supabase: any  // SupabaseClient
  llm: QwenTurboClient
  cartesia: CartesiaClient
  env: {
    SUPABASE_URL: string
    SUPABASE_KEY: string
    OPENAI_API_KEY: string
    CARTESIA_API_KEY: string
    AUDIO_BUCKET: R2Bucket
  }
}

// ----------------------------------------------------------------------------
// HANDLER REGISTRY - Maps event types to their handlers
// ----------------------------------------------------------------------------

export const EVENT_HANDLERS: Record<
  string,
  (envelope: EventEnvelope, ctx: HandlerContext) => Promise<EventHandlerResult>
> = {
  // Response events
  'response.audio.uploaded': handleResponseAudioUploaded,

  // AI events (optional - for text synthesis if needed)
  'ai.synthesis.started': handleAISynthesisStarted,
}

// ----------------------------------------------------------------------------
// RESPONSE HANDLERS
// ----------------------------------------------------------------------------

/**
 * Handles: response.audio.uploaded
 *
 * When a user uploads audio, this handler:
 * 1. Downloads the audio from R2
 * 2. Sends to Cartesia for transcription
 * 3. Updates the response with transcription text
 * 4. Publishes response.transcribed event
 */
async function handleResponseAudioUploaded(
  envelope: EventEnvelope,
  ctx: HandlerContext
): Promise<EventHandlerResult> {
  const { responseId, audioKey } = envelope.data as {
    responseId: string
    audioKey: string
    audioUrl: string
    fileSize: number
    duration: number
    mimeType: string
  }

  try {
    // 1. Get the response from DB
    const { data: response, error: fetchError } = await ctx.supabase
      .from('responses')
      .select('*')
      .eq('id', responseId)
      .single()

    if (fetchError || !response) {
      return {
        success: false,
        shouldRetry: false,  // Not retryable if record doesn't exist
        error: fetchError?.message || 'Response not found',
      }
    }

    // 2. Download audio from R2
    const audioObject = await ctx.env.AUDIO_BUCKET.get(audioKey)
    if (!audioObject) {
      return {
        success: false,
        shouldRetry: true,  // Retryable - might be temporary R2 issue
        error: 'Audio file not found in R2',
      }
    }

    // 3. Convert R2 object to ArrayBuffer for Cartesia
    const audioBuffer = await audioObject.arrayBuffer()

    // 4. Transcribe with Cartesia
    const transcriptionResult = await ctx.cartesia.transcribeAudio(audioBuffer)

    // 5. Update response with transcription
    const { error: updateError } = await ctx.supabase
      .from('responses')
      .update({
        transcription_text: transcriptionResult.text,
        duration_seconds: transcriptionResult.duration_seconds,
        processing_status: 'completed',
      })
      .eq('id', responseId)

    if (updateError) {
      return {
        success: false,
        shouldRetry: true,
        error: updateError.message,
      }
    }

    // 6. All done! The app can now play audio clips sequentially
    // No need for backend processing - iOS app handles playback

    return {
      success: true,
      metadata: {
        transcriptionLength: transcriptionResult.text.length,
        duration: transcriptionResult.duration_seconds,
      },
    }
  } catch (error) {
    return {
      success: false,
      shouldRetry: true,
      error: error instanceof Error ? error.message : 'Unknown error',
    }
  }
}

// ----------------------------------------------------------------------------
// AI HANDLERS
// ----------------------------------------------------------------------------

/**
 * Handles: ai.synthesis.started
 *
 * When a story is ready for synthesis, this handler:
 * 1. Fetches all responses for the story
 * 2. Calls LLM to synthesize the story
 * 3. Generates cover image
 * 4. Marks story as completed
 * 5. Triggers notification
 */
async function handleAISynthesisStarted(
  envelope: EventEnvelope,
  ctx: HandlerContext
): Promise<EventHandlerResult> {
  const { storyId } = envelope.data as {
    storyId: string
    responseCount: number
    promptText: string
  }

  try {
    // 1. Fetch story and responses
    const { data: story, error: storyError } = await ctx.supabase
      .from('stories')
      .select(`
        *,
        prompt:prompts(text),
        responses(
          id,
          transcription_text,
          profiles(full_name, role, avatar_url)
        )
      `)
      .eq('id', storyId)
      .single()

    if (storyError || !story) {
      return {
        success: false,
        shouldRetry: false,
        error: storyError?.message || 'Story not found',
      }
    }

    // 2. Prepare data for LLM
    const synthesisInput = {
      responses: story.responses.map((r: any) => ({
        id: r.id,
        transcription_text: r.transcription_text,
        profiles: r.profiles,
      })),
      promptText: story.prompt?.text || '',
    }

    // 3. Call LLM for synthesis
    const synthesisResult = await ctx.llm.synthesizeStory(synthesisInput)

    // 4. Generate cover image (placeholder for now - would use Replicate)
    const coverImageUrl = 'https://placeholder.com/story-cover.jpg'

    // 5. Update story with results
    const { error: updateError } = await ctx.supabase
      .from('stories')
      .update({
        title: synthesisResult.title,
        summary_text: synthesisResult.summary,
        cover_image_url: coverImageUrl,
        is_completed: true,
        voice_count: story.responses.length,
      })
      .eq('id', storyId)

    if (updateError) {
      return {
        success: false,
        shouldRetry: true,
        error: updateError.message,
      }
    }

    // 6. Create story segments for panel generation
    for (const segment of synthesisResult.segments) {
      await ctx.supabase
        .from('story_segments')
        .insert({
          story_id: storyId,
          response_id: segment.response_id,
          order_index: segment.order_index,
          speaker_name: segment.speaker_name,
          speaker_role: segment.speaker_role,
          speaker_age: segment.speaker_age,
          dialogue_snippet: segment.dialogue_snippet,
        })
    }

    // 7. Publish completion event
    // In real implementation, this would go through the event publisher
    // For now, we'll return success

    return {
      success: true,
      metadata: {
        title: synthesisResult.title,
        segmentCount: synthesisResult.segments.length,
      },
    }
  } catch (error) {
    return {
      success: false,
      shouldRetry: true,
      error: error instanceof Error ? error.message : 'Unknown error',
    }
  }
}

// ----------------------------------------------------------------------------
// HELPER FUNCTIONS
// ----------------------------------------------------------------------------

/**
 * Publishes ai.synthesis.started event
 *
 * This is for the optional text synthesis feature.
 */
async function publishSynthesisStartedEvent(storyId: string, ctx: HandlerContext): Promise<void> {
  // In production, this would call the event publisher
  // For now, this is a placeholder
  console.log(`[TODO] Publish ai.synthesis.started for story: ${storyId}`)
}

// ----------------------------------------------------------------------------
// QUEUE CONSUMER - Cloudflare Workers queue handler
// ----------------------------------------------------------------------------

export interface QueueMessage {
  body: EventEnvelope
}

/**
 * Main queue consumer - routes events to appropriate handlers
 */
export async function handleQueueBatch(
  batch: MessageBatch<QueueMessage>,
  ctx: HandlerContext
): Promise<void> {
  const results = await Promise.allSettled(
    batch.messages.map(async (message) => {
      const envelope = message.body as EventEnvelope

      // Find handler for this event type
      const handler = EVENT_HANDLERS[envelope.type]

      if (!handler) {
        console.warn(`No handler registered for event type: ${envelope.type}`)
        message.ack()
        return
      }

      // Execute handler
      const result = await handler(envelope, ctx)

      // Ack or retry based on result
      if (result.success) {
        message.ack()
      } else if (result.shouldRetry) {
        message.retry({
          delaySeconds: Math.pow(2, envelope.metadata?.retryCount || 0),  // Exponential backoff
        })
      } else {
        // Don't retry - send to DLQ if available
        message.ack()
      }
    })
  )

  // Log any unexpected errors
  for (const result of results) {
    if (result.status === 'rejected') {
      console.error('Unexpected handler error:', result.reason)
    }
  }
}
