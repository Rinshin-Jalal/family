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
import { createCartesiaClient, DEFAULT_VOICES } from '../ai/cartesia'
import { generateStorageKey } from '../ai/r2'
import type { Database } from '../types'
import { getSupabaseFromEnv } from '../utils/supabase'

// ============================================================================
// TYPES
// ============================================================================

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

// Global Supabase client (initialized once for the job)
const supabase = getSupabaseFromEnv()

/**
 * Fetch story with all responses
 */
async function fetchStoryWithResponses(storyId: string) {
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
        tts_audio_key,
        tts_generated_at,
        tts_duration_seconds,
        tts_voice_id,
        user_id,
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

/**
 * Generate TTS audio for responses without audio
 *
 * For responses that have transcription_text but no audio recording,
 * this function generates TTS audio using Cartesia and uploads to Supabase storage.
 */
async function generateTTSForResponse(
  response: any,
  userId: string
): Promise<{ url: string; duration: number }> {
  // Check if TTS audio already exists
  if (response.tts_audio_key) {
    // Return existing TTS audio URL from Supabase
    const { data: { publicUrl } } = supabase.storage
      .from('audio')
      .getPublicUrl(response.tts_audio_key)

    return {
      url: publicUrl,
      duration: response.tts_duration_seconds || 0,
    }
  }

  // Check if we have transcription text
  if (!response.transcription_text) {
    throw new Error(`Response ${response.id} has no transcription text for TTS`)
  }

  // Initialize Cartesia client
  const cartesia = createCartesiaClient({
    apiKey: process.env.CARTESIA_API_KEY!,
  })

  // Select voice based on user profile (could be enhanced to store voice preference)
  const voice = DEFAULT_VOICES.narrator // Default narrator voice

  // Generate TTS audio
  const ttsResult = await cartesia.textToSpeech(response.transcription_text, {
    voice,
    outputFormat: 'mp3',
  })

  // Upload to Supabase storage
  const storageKey = generateStorageKey('audio', userId, `tts-${response.id}.mp3`)
  const buffer = Buffer.from(ttsResult.audioBuffer)

  const { data, error } = await supabase.storage
    .from('audio')
    .upload(storageKey, buffer, {
      contentType: 'audio/mpeg',
      upsert: false,
    })

  if (error) {
    throw new Error(`Failed to upload TTS audio: ${error.message}`)
  }

  // Get public URL
  const { data: { publicUrl } } = supabase.storage
    .from('audio')
    .getPublicUrl(storageKey)

  // Update response with TTS metadata
  await supabase
    .from('responses')
    .update({
      tts_audio_key: storageKey,
      tts_generated_at: new Date().toISOString(),
      tts_duration_seconds: ttsResult.duration,
    })
    .eq('id', response.id)

  return {
    url: publicUrl,
    duration: ttsResult.duration,
  }
}

/**
 * Prepare audio clips from responses (handles both audio and TTS)
 */
async function prepareAudioClips(responses: any[]) {
  const audioClips: Array<{
    id: string
    url: string
    speakerName: string
    duration: number
  }> = []

  for (const response of responses) {
    // Skip responses with no transcription
    if (!response.transcription_text) {
      console.log(`Skipping response ${response.id} - no transcription`)
      continue
    }

    // Case 1: Has original audio recording
    if (response.media_url && !response.media_url.includes('tts-')) {
      audioClips.push({
        id: response.id,
        url: response.media_url,
        speakerName: response.profiles?.full_name || 'Unknown',
        duration: response.duration_seconds || 0,
      })
      continue
    }

    // Case 2: No audio but has transcription - generate TTS
    try {
      console.log(`Generating TTS for response ${response.id} - ${response.transcription_text?.substring(0, 50)}...`)
      const ttsAudio = await generateTTSForResponse(response, response.user_id || 'unknown')

      audioClips.push({
        id: response.id,
        url: ttsAudio.url,
        speakerName: response.profiles?.full_name || 'Unknown',
        duration: ttsAudio.duration,
      })
    } catch (error) {
      console.error(`Failed to generate TTS for response ${response.id}:`, error)
      // Continue with other responses
    }
  }

  return audioClips
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
    // Step 1: Update story status to 'generating'
    await updateStoryStatus(payload.storyId, {
      podcast_status: 'generating',
    })

    try {
      // Step 2: Fetch story and all responses
      const story = await fetchStoryWithResponses(payload.storyId)

      // Step 3: Prepare audio clips (handles both original audio and TTS)
      console.log(`Preparing audio clips for story ${payload.storyId}...`)
      const audioClips = await prepareAudioClips(story.responses)

      if (audioClips.length === 0) {
        throw new Error('No audio clips found for podcast generation - all responses lack transcriptions')
      }

      console.log(`Generated ${audioClips.length} audio clips for podcast`)

      // Step 4: Initialize audio processor with Supabase storage
      const processor = createAudioProcessor({
        ...DEFAULT_AUDIO_PROCESSOR_CONFIG,
        supabase,
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
        audioClipsCount: audioClips.length,
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
    // Step 1: Update story status to 'regenerating'
    await updateStoryStatus(payload.storyId, {
      podcast_status: 'regenerating',
    })

    try {
      // Step 2: Fetch story and all responses
      const story = await fetchStoryWithResponses(payload.storyId)

      // Step 3: Prepare audio clips (handles both original audio and TTS)
      console.log(`Preparing audio clips for story ${payload.storyId} regeneration...`)
      const audioClips = await prepareAudioClips(story.responses)

      if (audioClips.length === 0) {
        throw new Error('No audio clips found for podcast regeneration')
      }

      console.log(`Regenerating podcast with ${audioClips.length} audio clips`)

      // Step 4: Initialize audio processor with Supabase storage
      const processor = createAudioProcessor({
        ...DEFAULT_AUDIO_PROCESSOR_CONFIG,
        supabase,
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
        audioClipsCount: audioClips.length,
      }

    } catch (error) {
      await updateStoryStatus(supabase, payload.storyId, {
        podcast_status: 'failed',
      })

      throw error
    }
  },
})
