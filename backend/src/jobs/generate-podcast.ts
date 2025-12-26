// ============================================================================
// TRIGGER.DEV JOBS - Podcast Generation
// ============================================================================
//
// Long-running background jobs for podcast generation.
// These jobs run on Trigger.dev infrastructure, not constrained by
// Cloudflare Workers CPU limits.
//
// Jobs:
// - generate-podcast: Weave audio clips into a podcast
// - regenerate-podcast: Re-generate with a new perspective
// ============================================================================

import { client } from '@trigger.dev/sdk'
import { createAudioProcessor, DEFAULT_AUDIO_PROCESSOR_CONFIG } from '../ai/audio-processor'
import { createClient } from '@supabase/supabase-js'
import type { Database } from '../types'

// ============================================================================
// TYPES
// ============================================================================

type SupabaseClient = ReturnType<typeof createClient<Database>>

interface GeneratePodcastJobPayload {
  storyId: string
  responseIds: string[]
  promptText: string
}

interface RegeneratePodcastJobPayload {
  storyId: string
  newResponseId: string
  previousVersion: number
}

// ============================================================================
// SUPABASE HELPERS
// ============================================================================

/**
 * Create Supabase client for Trigger.dev jobs
 */
function createSupabaseClientForJob(): SupabaseClient {
  return createClient<Database>(
    process.env.SUPABASE_URL!,
    process.env.SUPABASE_KEY!,
    {
      auth: { persistSession: false },
    }
  )
}

/**
 * Fetch story with all responses
 */
async function fetchStoryWithResponses(supabase: SupabaseClient, storyId: string) {
  const { data, error } = await supabase
    .from('stories')
    .select(`
      *,
      prompt:prompts(text),
      responses(
        id,
        media_url,
        audio_key,
        transcription_text,
        duration_seconds,
        profiles(full_name, role)
      )
    `)
    .eq('id', storyId)
    .single()

  if (error) {
    throw new Error(`Failed to fetch story: ${error.message}`)
  }

  if (!data) {
    throw new Error(`Story not found: ${storyId}`)
  }

  return data
}

/**
 * Update story podcast status
 */
async function updateStoryStatus(
  supabase: SupabaseClient,
  storyId: string,
  updates: {
    podcast_status: 'generating' | 'ready' | 'failed' | 'regenerating'
    podcast_url?: string
    podcast_duration_seconds?: number
    podcast_version?: number
    podcast_generated_at?: string
  }
) {
  const { error } = await supabase
    .from('stories')
    .update(updates)
    .eq('id', storyId)

  if (error) {
    throw new Error(`Failed to update story: ${error.message}`)
  }
}

// ============================================================================
// JOB: GENERATE PODCAST
// ============================================================================

/**
 * Generate podcast from transcribed responses
 *
 * This job is triggered when all responses for a story are transcribed.
 * It weaves the audio clips together with background music.
 */
client.defineJob({
  id: 'generate-podcast',
  name: 'Generate Story Podcast',
  version: '1.0.0',
  trigger: {
    event: 'story.ready.for.podcast',
  },
  run: async (payload: GeneratePodcastJobPayload, { ctx }) => {
    const supabase = createSupabaseClientForJob()

    // Step 1: Update story status to 'generating'
    await updateStoryStatus(supabase, payload.storyId, {
      podcast_status: 'generating',
    })

    try {
      // Step 2: Fetch story and all responses
      const story = await fetchStoryWithResponses(supabase, payload.storyId)

      // Step 3: Prepare audio clips
      const audioClips = story.responses
        .filter(r => r.media_url && r.transcription_text)
        .map(r => ({
          id: r.id,
          url: r.media_url!,
          speakerName: r.profiles?.full_name || 'Unknown',
          duration: r.duration_seconds,
        }))

      if (audioClips.length === 0) {
        throw new Error('No audio clips found for podcast generation')
      }

      // Step 4: Initialize audio processor
      const processor = createAudioProcessor({
        ...DEFAULT_AUDIO_PROCESSOR_CONFIG,
        provider: 'replicate',
        replicateApiKey: process.env.REPLICATE_API_TOKEN,
      })

      // Step 5: Generate podcast
      const result = await processor.generatePodcast({
        storyId: payload.storyId,
        audioClips,
        storySummary: story.prompt?.text,
        addMusic: true,
        musicStyle: 'warm',  // Could be AI-selected based on content
      })

      // Step 6: Update story with podcast URL
      await updateStoryStatus(supabase, payload.storyId, {
        podcast_status: 'ready',
        podcast_url: result.podcastUrl,
        podcast_duration_seconds: result.duration,
        podcast_version: (story.podcast_version || 0) + 1,
        podcast_generated_at: new Date().toISOString(),
      })

      // Step 7: Mark responses as processed
      for (const clip of audioClips) {
        await supabase
          .from('responses')
          .update({ audio_processed_at: new Date().toISOString() })
          .eq('id', clip.id)
      }

      return {
        success: true,
        storyId: payload.storyId,
        podcastUrl: result.podcastUrl,
        duration: result.duration,
      }

    } catch (error) {
      // Mark as failed
      await updateStoryStatus(supabase, payload.storyId, {
        podcast_status: 'failed',
      })

      throw error
    }
  },
})

// ============================================================================
// JOB: REGENERATE PODCAST
// ============================================================================

/**
 * Regenerate podcast with new perspective
 *
 * This job is triggered when a new response is added to a completed story.
 * It regenerates the entire podcast including the new voice.
 */
client.defineJob({
  id: 'regenerate-podcast',
  name: 'Regenerate Story Podcast',
  version: '1.0.0',
  trigger: {
    event: 'story.podcast.regenerating',
  },
  run: async (payload: RegeneratePodcastJobPayload, { ctx }) => {
    const supabase = createSupabaseClientForJob()

    // Step 1: Update story status to 'regenerating'
    await updateStoryStatus(supabase, payload.storyId, {
      podcast_status: 'regenerating',
    })

    try {
      // Step 2: Fetch story and all responses
      const story = await fetchStoryWithResponses(supabase, payload.storyId)

      // Step 3: Prepare audio clips (including new one)
      const audioClips = story.responses
        .filter(r => r.media_url && r.transcription_text)
        .map(r => ({
          id: r.id,
          url: r.media_url!,
          speakerName: r.profiles?.full_name || 'Unknown',
          duration: r.duration_seconds,
        }))

      // Step 4: Initialize audio processor
      const processor = createAudioProcessor({
        ...DEFAULT_AUDIO_PROCESSOR_CONFIG,
        provider: 'replicate',
        replicateApiKey: process.env.REPLICATE_API_TOKEN,
      })

      // Step 5: Generate podcast with incremented version
      const result = await processor.generatePodcast({
        storyId: payload.storyId,
        audioClips,
        storySummary: story.prompt?.text,
        addMusic: true,
        musicStyle: 'warm',
      })

      // Step 6: Update story with new podcast
      await updateStoryStatus(supabase, payload.storyId, {
        podcast_status: 'ready',
        podcast_url: result.podcastUrl,
        podcast_duration_seconds: result.duration,
        podcast_version: payload.previousVersion + 1,
        podcast_generated_at: new Date().toISOString(),
      })

      return {
        success: true,
        storyId: payload.storyId,
        podcastUrl: result.podcastUrl,
        duration: result.duration,
        version: payload.previousVersion + 1,
      }

    } catch (error) {
      await updateStoryStatus(supabase, payload.storyId, {
        podcast_status: 'failed',
      })

      throw error
    }
  },
})
