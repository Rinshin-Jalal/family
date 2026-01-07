// ============================================================================
// EVENT PUBLISHER - Emits domain events to the queue
// ============================================================================

import type {
  EventEnvelope,
  EventType,
  EventMetadata,
  EventSource,
} from './types'

/**
 * Publisher interface - different implementations for different backends
 */
export interface EventPublisher {
  publish<T>(type: EventType, data: T, metadata?: Partial<EventMetadata>): Promise<string>
  publishBatch<T>(events: Array<{ type: EventType; data: T; metadata?: Partial<EventMetadata> }>): Promise<string[]>
}

/**
 * Cloudflare Queues implementation of EventPublisher
 *
 * Uses Cloudflare Workers Queues for reliable event delivery.
 */
export class QueueEventPublisher implements EventPublisher {
  constructor(
    private queue: ExportedHandler<Env>['queue'],
    private source: EventSource = 'api'
  ) {}

  async publish<T>(
    type: EventType,
    data: T,
    metadata?: Partial<EventMetadata>
  ): Promise<string> {
    const envelope: EventEnvelope<T> = {
      id: crypto.randomUUID(),
      type,
      timestamp: new Date().toISOString(),
      version: '1.0',
      data,
      metadata: {
        source: this.source,
        ...metadata,
      },
    }

    // Send to Cloudflare Queue
    await this.queue.send(envelope)

    return envelope.id
  }

  async publishBatch<T>(
    events: Array<{ type: EventType; data: T; metadata?: Partial<EventMetadata> }>
  ): Promise<string[]> {
    const envelopes: EventEnvelope<T>[] = events.map((event) => ({
      id: crypto.randomUUID(),
      type: event.type,
      timestamp: new Date().toISOString(),
      version: '1.0',
      data: event.data,
      metadata: {
        source: this.source,
        ...event.metadata,
      },
    }))

    // Send batch to Cloudflare Queue
    await this.queue.sendBatch(envelopes.map((e) => ({ body: e })))

    return envelopes.map((e) => e.id)
  }
}

/**
 * In-memory publisher for testing and development
 *
 * NOT suitable for production - events are lost on restart.
 */
export class InMemoryEventPublisher implements EventPublisher {
  private handlers: Map<EventType, Array<(envelope: EventEnvelope) => void>> = new Map()

  on(eventType: EventType, handler: (envelope: EventEnvelope) => void): void {
    const existing = this.handlers.get(eventType) || []
    this.handlers.set(eventType, [...existing, handler])
  }

  async publish<T>(
    type: EventType,
    data: T,
    metadata?: Partial<EventMetadata>
  ): Promise<string> {
    const envelope: EventEnvelope<T> = {
      id: crypto.randomUUID(),
      type,
      timestamp: new Date().toISOString(),
      version: '1.0',
      data,
      metadata: {
        source: 'api',
        ...metadata,
      },
    }

    // Trigger handlers synchronously for testing
    const handlers = this.handlers.get(type) || []
    for (const handler of handlers) {
      handler(envelope)
    }

    return envelope.id
  }

  async publishBatch<T>(
    events: Array<{ type: EventType; data: T; metadata?: Partial<EventMetadata> }>
  ): Promise<string[]> {
    const ids: string[] = []
    for (const event of events) {
      const id = await this.publish(event.type, event.data, event.metadata)
      ids.push(id)
    }
    return ids
  }

  // Test helper - clear all handlers
  clear(): void {
    this.handlers.clear()
  }
}

/**
 * Domain-specific event publishers with typed methods
 *
 * These provide a clean API for routes to publish domain events
 * without worrying about envelope structure.
 */
export class DomainEventPublisher {
  constructor(private publisher: EventPublisher) {}

  // Story events
  async publishStoryCreated(data: {
    storyId: string
    promptId: string
    familyId: string
    createdBy: string
  }): Promise<string> {
    return this.publisher.publish('story.created', data, {
      userId: data.createdBy,
      familyId: data.familyId,
    })
  }

  async publishStoryCompleted(data: {
    storyId: string
    title: string
    summary: string
    coverImageUrl?: string
    voiceCount: number
    segments: number
  }): Promise<string> {
    return this.publisher.publish('story.completed', data)
  }

  // Response events
  async publishResponseSubmitted(data: {
    responseId: string
    storyId: string | null
    promptId: string
    userId: string
    familyId: string
    source: 'app_audio' | 'app_text' | 'phone_ai'
  }): Promise<string> {
    return this.publisher.publish('response.submitted', data, {
      userId: data.userId,
      familyId: data.familyId,
    })
  }

  async publishResponseAudioUploaded(data: {
    responseId: string
    audioKey: string
    audioUrl: string
    fileSize: number
    duration: number
    mimeType: string
  }): Promise<string> {
    return this.publisher.publish('response.audio.uploaded', data)
  }

  async publishResponseTranscribed(data: {
    responseId: string
    storyId: string | null
    transcriptionText: string
    durationSeconds: number
    confidence?: number
  }): Promise<string> {
    return this.publisher.publish('response.transcribed', data)
  }

  // AI events
  async publishAISynthesisStarted(data: {
    storyId: string
    responseCount: number
    promptText: string
  }): Promise<string> {
    return this.publisher.publish('ai.synthesis.started', data)
  }

  async publishAISynthesisCompleted(data: {
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
  }): Promise<string> {
    return this.publisher.publish('ai.synthesis.completed', data)
  }

  // Notification events
  async publishNotificationStoryCompleted(data: {
    storyId: string
    familyId: string
    title: string
    recipientUserIds: string[]
  }): Promise<string> {
    return this.publisher.publish('notification.story.completed', data)
  }

  // Wisdom events
  async publishWisdomStoryTagRequested(data: {
    storyId: string
    triggeredBy: 'story_completion' | 'manual_request'
  }): Promise<string> {
    return this.publisher.publish('wisdom.story.tag.requested', data)
  }

  async publishWisdomStoryTagCompleted(data: {
    storyId: string
    emotionTags: string[]
    situationTags: string[]
    lessonTags: string[]
    guidanceTags: string[]
    questionKeywords: string[]
    confidence: number
  }): Promise<string> {
    return this.publisher.publish('wisdom.story.tag.completed', data)
  }

  async publishWisdomStoryTagFailed(data: {
    storyId: string
    error: string
    retryable: boolean
    attemptNumber: number
  }): Promise<string> {
    return this.publisher.publish('wisdom.story.tag.failed', data)
  }

  async publishWisdomRequestCreated(data: {
    requestId: string
    question: string
    requesterId: string
    requesterName: string
    targetProfileIds: string[]
    relatedStoryId?: string
  }): Promise<string> {
    return this.publisher.publish('wisdom.request.created', data, {
      userId: data.requesterId,
    })
  }

  async publishWisdomRequestNotificationSent(data: {
    requestId: string
    eldersNotified: number
    appUsersNotified: number
  }): Promise<string> {
    return this.publisher.publish('wisdom.request.notification.sent', data)
  }

  async publishWisdomSummaryRequested(data: {
    storyIds: string[]
    question: string
    userId: string
  }): Promise<string> {
    return this.publisher.publish('wisdom.summary.requested', data, {
      userId: data.userId,
    })
  }

  async publishWisdomSummaryCompleted(data: {
    primaryStoryId: string
    summary: string
    whatHappened: string[]
    whatLearned: string[]
    guidance: string[]
    generation?: string
  }): Promise<string> {
    return this.publisher.publish('wisdom.summary.completed', data)
  }

  async publishWisdomSummaryFailed(data: {
    primaryStoryId: string
    error: string
    retryable: boolean
  }): Promise<string> {
    return this.publisher.publish('wisdom.summary.failed', data)
  }
}

/**
 * Factory function to create domain publisher from bindings
 */
export function createEventPublisher(queue: ExportedHandler<Env>['queue']): DomainEventPublisher {
  const publisher = new QueueEventPublisher(queue)
  return new DomainEventPublisher(publisher)
}
