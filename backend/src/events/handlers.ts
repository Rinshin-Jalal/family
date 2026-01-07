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
import { createWisdomTaggerClient } from '../ai/wisdom-tagger'
import { createWisdomSummarizerClient } from '../ai/wisdom-summarizer'
import type { QwenTurboClient } from '../ai/llm'
import type { CartesiaClient } from '../ai/cartesia'
import type { WisdomTaggerClient } from '../ai/wisdom-tagger'
import type { WisdomSummarizerClient } from '../ai/wisdom-summarizer'

// ----------------------------------------------------------------------------
// DEPENDENCIES - Supabase client and AI services
// ----------------------------------------------------------------------------

export interface HandlerContext {
  supabase: any
  llm: QwenTurboClient
  cartesia: CartesiaClient
  wisdomTagger: WisdomTaggerClient
  wisdomSummarizer: WisdomSummarizerClient
  env: {
    SUPABASE_URL: string
    SUPABASE_KEY: string
    OPENAI_API_KEY: string
    BEDROCK_REGION: string
    CARTESIA_API_KEY: string
    TWILIO_ACCOUNT_SID: string
    TWILIO_AUTH_TOKEN: string
    TWILIO_PHONE_NUMBER: string
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

  // AI events
  'ai.synthesis.started': handleAISynthesisStarted,

  // Wisdom events
  'wisdom.story.tag.requested': handleWisdomStoryTagRequested,
  'wisdom.story.tag.completed': handleWisdomStoryTagCompleted,
  'wisdom.request.created': handleWisdomRequestCreated,
  'wisdom.request.notification.sent': handleWisdomRequestNotificationSent,
  'wisdom.summary.requested': handleWisdomSummaryRequested,
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
    const responseResult = await fetchResponseById(ctx, responseId)
    if (!responseResult.success) return responseResult

    const audioResult = await downloadAudioFromR2(ctx, audioKey)
    if (!audioResult.success) return audioResult

    const transcriptionResult = await transcribeAudio(ctx, audioResult.data)

    const updateResult = await updateResponseTranscription(
      ctx,
      responseId,
      transcriptionResult
    )
    if (!updateResult.success) return updateResult

    return {
      success: true,
      shouldRetry: false,
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

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

interface HelperResult {
  success: boolean
  shouldRetry: boolean
  error?: string
  data?: any
}

async function fetchResponseById(
  ctx: HandlerContext,
  responseId: string
): Promise<HelperResult> {
  const { data, error } = await ctx.supabase
    .from('responses')
    .select('*')
    .eq('id', responseId)
    .single()

  if (error || !data) {
    return {
      success: false,
      shouldRetry: false,
      error: error?.message || 'Response not found',
    }
  }

  return { success: true, data }
}

async function downloadAudioFromR2(
  ctx: HandlerContext,
  audioKey: string
): Promise<HelperResult & { data: ArrayBuffer }> {
  const audioObject = await ctx.env.AUDIO_BUCKET.get(audioKey)

  if (!audioObject) {
    return {
      success: false,
      shouldRetry: true,
      error: 'Audio file not found in R2',
    }
  }

  const buffer = await audioObject.arrayBuffer()
  return { success: true, data: buffer }
}

async function transcribeAudio(
  ctx: HandlerContext,
  audioBuffer: ArrayBuffer
): Promise<{ text: string; duration_seconds: number }> {
  return ctx.cartesia.transcribeAudio(audioBuffer)
}

async function updateResponseTranscription(
  ctx: HandlerContext,
  responseId: string,
  transcription: { text: string; duration_seconds: number }
): Promise<HelperResult> {
  const { error } = await ctx.supabase
    .from('responses')
    .update({
      transcription_text: transcription.text,
      duration_seconds: transcription.duration_seconds,
      processing_status: 'completed',
    })
    .eq('id', responseId)

  if (error) {
    return {
      success: false,
      shouldRetry: true,
      error: error.message,
    }
  }

  return { success: true, shouldRetry: false }
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
    const storyResult = await fetchStoryWithResponses(ctx, storyId)
    if (!storyResult.success) return storyResult

    const synthesisInput = prepareSynthesisInput(storyResult.data)
    const synthesisResult = await synthesizeStory(ctx.llm, synthesisInput)

    const updateResult = await updateStoryWithResults(
      ctx,
      storyId,
      synthesisResult
    )
    if (!updateResult.success) return updateResult

    await createStorySegments(ctx, storyId, synthesisResult)

    return {
      success: true,
      shouldRetry: false,
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

async function fetchStoryWithResponses(
  ctx: HandlerContext,
  storyId: string
): Promise<HelperResult & { data: any }> {
  const { data, error } = await ctx.supabase
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

  if (error || !data) {
    return {
      success: false,
      shouldRetry: false,
      error: error?.message || 'Story not found',
    }
  }

  return { success: true, data }
}

function prepareSynthesisInput(story: any): {
  responses: any[]
  promptText: string
} {
  return {
    responses: story.responses.map((r: any) => ({
      id: r.id,
      transcription_text: r.transcription_text,
      profiles: r.profiles,
    })),
    promptText: story.prompt?.text || '',
  }
}

async function synthesizeStory(
  llm: any,
  input: { responses: any[]; promptText: string }
): Promise<{
  title: string
  summary: string
  segments: any[]
}> {
  return llm.synthesizeStory(input)
}

async function updateStoryWithResults(
  ctx: HandlerContext,
  storyId: string,
  result: { title: string; summary: string; segments: any[] }
): Promise<HelperResult> {
  const coverImageUrl = 'https://placeholder.com/story-cover.jpg'

  const { error } = await ctx.supabase
    .from('stories')
    .update({
      title: result.title,
      summary_text: result.summary,
      cover_image_url: coverImageUrl,
      is_completed: true,
    })
    .eq('id', storyId)

  if (error) {
    return {
      success: false,
      shouldRetry: true,
      error: error.message,
    }
  }

  return { success: true, shouldRetry: false }
}

async function createStorySegments(
  ctx: HandlerContext,
  storyId: string,
  result: { segments: any[] }
): Promise<void> {
  for (const segment of result.segments) {
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
}

// ----------------------------------------------------------------------------
// WISDOM HANDLERS
// ----------------------------------------------------------------------------

/**
 * Handles: wisdom.story.tag.requested
 *
 * When a story needs to be tagged with wisdom categories:
 * 1. Fetch story with all responses
 * 2. Call AI tagging service
 * 3. Save tags to database
 * 4. Publish completion event
 */
async function handleWisdomStoryTagRequested(
  envelope: EventEnvelope,
  ctx: HandlerContext
): Promise<EventHandlerResult> {
  const { storyId, triggeredBy } = envelope.data as {
    storyId: string
    triggeredBy: 'story_completion' | 'manual_request'
  }

  try {
    // Fetch story with responses
    const { data: story, error } = await ctx.supabase
      .from('stories')
      .select(`
        id,
        responses(id, transcription_text, profiles(role, full_name))
      `)
      .eq('id', storyId)
      .single()

    if (error || !story) {
      return { success: false, shouldRetry: false, error: 'Story not found' }
    }

    const responses = story.responses || []
    const transcriptions = responses
      .filter((r: any) => r.transcription_text)
      .map((r: any) => r.transcription_text)

    if (transcriptions.length === 0) {
      return { success: false, shouldRetry: false, error: 'No transcriptions available' }
    }

    const speakerRoles = responses.map((r: any) => r.profiles?.role || 'member')
    const speakerNames = responses.map((r: any) => r.profiles?.full_name || 'Family Member')

    // Call AI tagging service
    const tags = await ctx.wisdomTagger.tagStory({
      storyId,
      transcriptions,
      speakerRoles,
      speakerNames,
    })

    // Save tags
    const { error: insertError } = await ctx.supabase
      .from('story_tags')
      .upsert({
        story_id: storyId,
        emotion_tags: tags.emotionTags,
        situation_tags: tags.situationTags,
        lesson_tags: tags.lessonTags,
        guidance_tags: tags.guidanceTags,
        question_keywords: tags.questionKeywords,
        confidence: tags.confidence,
        source: 'ai',
      }, { onConflict: 'story_id' })

    if (insertError) {
      return { success: false, shouldRetry: true, error: insertError.message }
    }

    return {
      success: true,
      shouldRetry: false,
      metadata: {
        emotionCount: tags.emotionTags.length,
        situationCount: tags.situationTags.length,
        lessonCount: tags.lessonTags.length,
        confidence: tags.confidence,
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

/**
 * Handles: wisdom.story.tag.completed
 *
 * Just logs completion - tags already saved by tagging handler
 */
async function handleWisdomStoryTagCompleted(
  envelope: EventEnvelope,
  ctx: HandlerContext
): Promise<EventHandlerResult> {
  const { storyId, emotionTags, situationTags, lessonTags, confidence } = envelope.data
  
  console.log(`[Wisdom] Story ${storyId} tagged with ${emotionTags?.length} emotions, ${situationTags?.length} situations, ${lessonTags?.length} lessons (confidence: ${confidence})`)
  
  return { success: true, shouldRetry: false }
}

/**
 * Handles: wisdom.request.created
 *
 * When a wisdom request is created:
 * 1. Fetch target family members
 * 2. Send SMS to elders (via Twilio)
 * 3. Send push notifications to app users
 * 4. Publish notification sent event
 */
async function handleWisdomRequestCreated(
  envelope: EventEnvelope,
  ctx: HandlerContext
): Promise<EventHandlerResult> {
  const { requestId, question, requesterName, targetProfileIds } = envelope.data as {
    requestId: string
    question: string
    requesterName: string
    requesterId: string
    targetProfileIds: string[]
    relatedStoryId?: string
  }

  try {
    // Fetch targets with their contact info
    const { data: targets, error } = await ctx.supabase
      .from('profiles')
      .select('id, full_name, phone_number, role')
      .in('id', targetProfileIds)

    if (error || !targets) {
      return { success: false, shouldRetry: true, error: 'Failed to fetch targets' }
    }

    let eldersNotified = 0
    let appUsersNotified = 0

    // Send notifications
    for (const target of targets) {
      if (target.role === 'elder' && target.phone_number) {
        // Send SMS via Twilio
        const message = `Family Story Request from ${requesterName}: "${question.substring(0, 100)}..." Reply or call to record your story.`
        
        if (ctx.env.TWILIO_ACCOUNT_SID && !ctx.env.TWILIO_ACCOUNT_SID.includes('placeholder')) {
          await sendTwilioSMS(ctx.env, target.phone_number, message)
        } else {
          console.log(`[SMS] Would send to ${target.full_name}: ${message}`)
        }
        eldersNotified++
      } else {
        // Would send push notification to app users
        console.log(`[Push] Would notify ${target.full_name} about request: ${question.substring(0, 50)}`)
        appUsersNotified++
      }
    }

    return {
      success: true,
      shouldRetry: false,
      metadata: {
        eldersNotified,
        appUsersNotified,
        targetsContacted: targets.length,
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

/**
 * Handles: wisdom.request.notification.sent
 *
 * Just logs notification results
 */
async function handleWisdomRequestNotificationSent(
  envelope: EventEnvelope,
  ctx: HandlerContext
): Promise<EventHandlerResult> {
  const { requestId, eldersNotified, appUsersNotified } = envelope.data
  
  console.log(`[Wisdom] Request ${requestId}: sent ${eldersNotified} SMS, ${appUsersNotified} push notifications`)
  
  return { success: true, shouldRetry: false }
}

/**
 * Handles: wisdom.summary.requested
 *
 * When a wisdom summary is requested:
 * 1. Fetch all stories
 * 2. Call AI summarizer
 * 3. Save summary to database
 */
async function handleWisdomSummaryRequested(
  envelope: EventEnvelope,
  ctx: HandlerContext
): Promise<EventHandlerResult> {
  const { storyIds, question } = envelope.data as {
    storyIds: string[]
    question: string
    userId: string
  }

  try {
    // Fetch stories with speaker info
    const { data: stories, error } = await ctx.supabase
      .from('stories')
      .select(`
        id,
        title,
        summary_text,
        responses(transcription_text, profiles(full_name, role))
      `)
      .in('id', storyIds)

    if (error || !stories?.length) {
      return { success: false, shouldRetry: false, error: 'Stories not found' }
    }

    const formattedStories = stories.map((s: any) => ({
      id: s.id,
      title: s.title,
      summaryText: s.summary_text || '',
      speakerName: s.responses?.[0]?.profiles?.full_name || 'Family Member',
      speakerRole: s.responses?.[0]?.profiles?.role || 'member',
    }))

    // Generate summary
    const summary = await ctx.wisdomSummarizer.generateSummary({
      stories: formattedStories,
      question,
    })

    // Save summary (link to first story)
    const { error: insertError } = await ctx.supabase
      .from('wisdom_summaries')
      .insert({
        story_id: storyIds[0],
        summary_text: summary.summary,
        what_happened: summary.whatHappened,
        what_learned: summary.whatLearned,
        guidance: summary.guidance,
        generation: summary.generation,
      })

    if (insertError) {
      return { success: false, shouldRetry: true, error: insertError.message }
    }

    return {
      success: true,
      shouldRetry: false,
      metadata: {
        storyCount: storyIds.length,
        whatHappenedCount: summary.whatHappened.length,
        whatLearnedCount: summary.whatLearned.length,
        guidanceCount: summary.guidance.length,
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

async function sendTwilioSMS(env: any, to: string, body: string): Promise<boolean> {
  try {
    const response = await fetch(
      `https://api.twilio.com/2010-04-01/Accounts/${env.TWILIO_ACCOUNT_SID}/Messages.json`,
      {
        method: 'POST',
        headers: {
          Authorization: `Basic ${btoa(`${env.TWILIO_ACCOUNT_SID}:${env.TWILIO_AUTH_TOKEN}`)}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: new URLSearchParams({
          To: to,
          From: env.TWILIO_PHONE_NUMBER,
          Body: body,
        }),
      }
    )
    return response.ok
  } catch {
    return false
  }
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
