// ============================================================================
// EVENT-BASED ARCHITECTURE - CORE TYPES
// ============================================================================
//
// This defines the event system that decouples API requests from background
// processing. API routes publish events; worker queues consume them.
//
// Benefits:
// - Fast HTTP responses (just queue the event)
// - Automatic retries on failure
// - Horizontal scaling (multiple workers)
// - Clear separation of concerns
// ============================================================================

// ----------------------------------------------------------------------------
// EVENT ENVELOPE - All events wrapped in this structure
// ----------------------------------------------------------------------------

export interface EventEnvelope<T = unknown> {
  id: string
  type: EventType
  timestamp: string
  version: string
  data: T
  metadata: EventMetadata
}

export interface EventMetadata {
  correlationId?: string  // Link related events together
  causationId?: string    // Event that triggered this event
  userId?: string         // User who initiated
  familyId?: string       // Family context
  source: EventSource     // Where event originated
}

export type EventSource =
  | 'api'           // HTTP API endpoint
  | 'worker'        // Background worker
  | 'scheduler'     // Cron/scheduled task
  | 'webhook'       // External webhook

// ----------------------------------------------------------------------------
// ALL EVENT TYPES - Registry of domain events
// ----------------------------------------------------------------------------

export type EventType =
  // Story lifecycle events
  | 'story.created'
  | 'story.completed'
  | 'story.cover.generated'

  // Podcast events
  | 'story.ready.for.podcast'
  | 'story.podcast.ready'
  | 'story.podcast.failed'
  | 'story.podcast.regenerating'

  // Response events
  | 'response.submitted'
  | 'response.audio.uploaded'
  | 'response.transcribed'
  | 'response.transcription.failed'
  | 'response.ocr.requested'
  | 'response.ocr.completed'
  | 'response.ocr.failed'

  // AI processing events
  | 'ai.synthesis.started'
  | 'ai.synthesis.completed'
  | 'ai.synthesis.failed'
  | 'ai.image.generated'
  | 'ai.image.failed'

  // Notification events
  | 'notification.story.completed'
  | 'notification.response.received'

  // Wisdom events
  | 'wisdom.story.tag.requested'
  | 'wisdom.story.tag.completed'
  | 'wisdom.story.tag.failed'
  | 'wisdom.request.created'
  | 'wisdom.request.notification.sent'
  | 'wisdom.summary.requested'
  | 'wisdom.summary.completed'
  | 'wisdom.summary.failed'

  // Quote events
  | 'quote.generation.requested'
  | 'quote.generation.completed'
  | 'quote.generation.failed'

// ----------------------------------------------------------------------------
// STORY EVENTS
// ----------------------------------------------------------------------------

export interface StoryCreatedEvent {
  storyId: string
  promptId: string
  familyId: string
  createdBy: string
}

export interface StoryCompletedEvent {
  storyId: string
  title: string
  summary: string
  coverImageUrl?: string
  voiceCount: number
  segments: number
}

export interface StoryCoverGeneratedEvent {
  storyId: string
  coverImageUrl: string
  revisedPrompt?: string
}

// ----------------------------------------------------------------------------
// PODCAST EVENTS
// ----------------------------------------------------------------------------

export interface StoryReadyForPodcastEvent {
  storyId: string
  responseCount: number
  promptText: string
  responseIds: string[]
}

export interface StoryPodcastReadyEvent {
  storyId: string
  podcastUrl: string
  duration: number
  version: number
}

export interface StoryPodcastFailedEvent {
  storyId: string
  error: string
  retryable: boolean
  attemptNumber: number
}

export interface StoryPodcastRegeneratingEvent {
  storyId: string
  newResponseId: string
  previousVersion: number
}

// ----------------------------------------------------------------------------
// RESPONSE EVENTS
// ----------------------------------------------------------------------------

export interface ResponseSubmittedEvent {
  responseId: string
  storyId: string | null
  promptId: string
  userId: string
  familyId: string
  source: 'app_audio' | 'app_text' | 'phone_ai'
}

export interface ResponseAudioUploadedEvent {
  responseId: string
  audioKey: string
  audioUrl: string
  fileSize: number
  duration: number
  mimeType: string
}

export interface ResponseTranscribedEvent {
  responseId: string
  storyId: string | null
  transcriptionText: string
  durationSeconds: number
  confidence?: number
}

export interface ResponseTranscriptionFailedEvent {
  responseId: string
  error: string
  retryable: boolean
  attemptNumber: number
}

export interface ResponseOcrRequestedEvent {
  responseId: string
  fileKey: string
  fileUrl: string
  fileSize: number
  mimeType: string
  fileType: 'image' | 'document'
}

export interface ResponseOcrCompletedEvent {
  responseId: string
  storyId: string | null
  extractedText: string
  confidence?: number
  pageCount?: number
}

export interface ResponseOcrFailedEvent {
  responseId: string
  error: string
  retryable: boolean
  attemptNumber: number
}

// ----------------------------------------------------------------------------
// AI PROCESSING EVENTS
// ----------------------------------------------------------------------------

export interface AISynthesisStartedEvent {
  storyId: string
  responseCount: number
  promptText: string
}

export interface AISynthesisCompletedEvent {
  storyId: string
  title: string
  summary: string
  segments: Array<{
    orderIndex: number
    responseId: string
    speakerName: string
    speakerRole: string
    speakerAge: number
    dialogueSnippet: string
  }>
}

export interface AISynthesisFailedEvent {
  storyId: string
  error: string
  retryable: boolean
  attemptNumber: number
}

export interface AIImageGeneratedEvent {
  storyId: string
  imageUrl: string
  revisedPrompt: string
  provider: string
}

export interface AIImageFailedEvent {
  storyId: string
  error: string
  retryable: boolean
  attemptNumber: number
}

// ----------------------------------------------------------------------------
// NOTIFICATION EVENTS
// ----------------------------------------------------------------------------

export interface NotificationStoryCompletedEvent {
  storyId: string
  familyId: string
  title: string
  recipientUserIds: string[]
}

export interface NotificationResponseReceivedEvent {
  storyId: string
  responseId: string
  familyId: string
  responderName: string
  recipientUserIds: string[]
}

// ============================================================================
// WISDOM EVENTS
// ============================================================================

export interface WisdomStoryTagRequestedEvent {
  storyId: string
  triggeredBy: 'story_completion' | 'manual_request'
}

export interface WisdomStoryTagCompletedEvent {
  storyId: string
  emotionTags: string[]
  situationTags: string[]
  lessonTags: string[]
  guidanceTags: string[]
  questionKeywords: string[]
  confidence: number
}

export interface WisdomStoryTagFailedEvent {
  storyId: string
  error: string
  retryable: boolean
  attemptNumber: number
}

export interface WisdomRequestCreatedEvent {
  requestId: string
  question: string
  requesterId: string
  requesterName: string
  targetProfileIds: string[]
  relatedStoryId?: string
}

export interface WisdomRequestNotificationSentEvent {
  requestId: string
  eldersNotified: number
  appUsersNotified: number
}

export interface WisdomSummaryRequestedEvent {
  storyIds: string[]
  question: string
  userId: string
}

export interface WisdomSummaryCompletedEvent {
  primaryStoryId: string
  summary: string
  whatHappened: string[]
  whatLearned: string[]
  guidance: string[]
  generation?: string
}

export interface WisdomSummaryFailedEvent {
  primaryStoryId: string
  error: string
  retryable: boolean
}

// ============================================================================
// QUOTE EVENTS
// ============================================================================

export interface QuoteGenerationRequestedEvent {
  responseId: string
  storyId: string | null
  triggeredBy: 'response.transcribed' | 'story.completed'
}

export interface QuoteGenerationCompletedEvent {
  quoteId: string
  responseId: string
  storyId: string | null
  quoteText: string
  authorName: string
  authorRole: string
}

export interface QuoteGenerationFailedEvent {
  responseId: string
  error: string
  retryable: boolean
}

// ----------------------------------------------------------------------------
// EVENT HANDLER RESULT - What handlers return
// ----------------------------------------------------------------------------

export interface EventHandlerResult {
  success: boolean
  shouldRetry: boolean
  error?: string
  metadata?: Record<string, unknown>
}

// ----------------------------------------------------------------------------
// EVENT DISPATCHER CONFIG
// ----------------------------------------------------------------------------

export interface EventDispatcherConfig {
  maxRetries: number
  retryDelayMs: number
  deadLetterQueue: boolean
}

export const DEFAULT_EVENT_CONFIG: EventDispatcherConfig = {
  maxRetries: 3,
  retryDelayMs: 1000,
  deadLetterQueue: true,
}
