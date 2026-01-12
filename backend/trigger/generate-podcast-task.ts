// ============================================================================
// TRIGGER.DEV TASKS - Podcast Generation
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

import { task } from "@trigger.dev/sdk";
import { createAudioProcessor, DEFAULT_AUDIO_PROCESSOR_CONFIG } from "../src/ai/audio-processor";
import { createCartesiaClient, DEFAULT_VOICES } from "../src/ai/cartesia";
import { generateStorageKey } from "../src/ai/r2";
import { createClient } from "@supabase/supabase-js";

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

/**
 * Update story podcast status
 */
async function updateStoryStatus(
  supabase: ReturnType<typeof createClient>,
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
 */
async function generateTTSForResponse(
  supabase: ReturnType<typeof createClient>,
  response: any,
  userId: string
): Promise<{ url: string; duration: number }> {
  if (response.tts_audio_key) {
    const { data: { publicUrl } } = supabase.storage
      .from('audio')
      .getPublicUrl(response.tts_audio_key)

    return {
      url: publicUrl,
      duration: response.tts_duration_seconds || 0,
    }
  }

  if (!response.transcription_text) {
    throw new Error(`Response ${response.id} has no transcription text for TTS`)
  }

  const cartesia = createCartesiaClient({
    apiKey: process.env.CARTESIA_API_KEY!,
  })

  const voice = DEFAULT_VOICES.narrator

  const ttsResult = await cartesia.textToSpeech(response.transcription_text, {
    voice,
    outputFormat: 'mp3',
  })

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

  const { data: { publicUrl } } = supabase.storage
    .from('audio')
    .getPublicUrl(storageKey)

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
 * Prepare audio clips from responses
 */
async function prepareAudioClips(
  supabase: ReturnType<typeof createClient>,
  responses: any[]
) {
  const audioClips: Array<{
    id: string
    url: string
    speakerName: string
    duration: number
  }> = []

  for (const response of responses) {
    if (!response.transcription_text) {
      console.log(`Skipping response ${response.id} - no transcription`)
      continue
    }

    if (response.media_url && !response.media_url.includes('tts-')) {
      audioClips.push({
        id: response.id,
        url: response.media_url,
        speakerName: response.profiles?.full_name || 'Unknown',
        duration: response.duration_seconds || 0,
      })
      continue
    }

    try {
      console.log(`Generating TTS for response ${response.id}`)
      const ttsAudio = await generateTTSForResponse(supabase, response, response.user_id || 'unknown')

      audioClips.push({
        id: response.id,
        url: ttsAudio.url,
        speakerName: response.profiles?.full_name || 'Unknown',
        duration: ttsAudio.duration,
      })
    } catch (error) {
      console.error(`Failed to generate TTS for response ${response.id}:`, error)
    }
  }

  return audioClips
}

// ============================================================================
// TASK: GENERATE PODCAST
// ============================================================================

/**
 * Generate podcast from transcribed responses
 */
export const generatePodcastTask = task({
  id: "generate-podcast",
  name: "Generate Story Podcast",
  version: "1.0.0",
  retry: {
    maxAttempts: 3,
    factor: 2,
    minTimeoutInMs: 1000,
    maxTimeoutInMs: 30000,
  },
  run: async (payload: GeneratePodcastJobPayload, { ctx }) => {
    // Initialize Supabase client
    const supabase = createClient(
      process.env.SUPABASE_URL!,
      process.env.SUPABASE_KEY!
    )

    // Step 1: Update story status to 'generating'
    await updateStoryStatus(supabase, payload.storyId, {
      podcast_status: 'generating',
    })

    try {
      // Step 2: Fetch story and all responses
      const { data: story, error: storyError } = await supabase
        .from('stories')
        .select(`
          *,
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
        .eq('id', payload.storyId)
        .single()

      if (storyError || !story) {
        throw new Error(`Failed to fetch story: ${storyError?.message || 'Story not found'}`)
      }

      // Step 3: Prepare audio clips
      console.log(`Preparing audio clips for story ${payload.storyId}...`)
      const audioClips = await prepareAudioClips(supabase, story.responses || [])

      if (audioClips.length === 0) {
        throw new Error('No audio clips found for podcast generation')
      }

      console.log(`Generated ${audioClips.length} audio clips for podcast`)

      // Step 4: Initialize audio processor
      const processor = createAudioProcessor({
        ...DEFAULT_AUDIO_PROCESSOR_CONFIG,
        supabase,
      })

      // Step 5: Generate podcast
      const result = await processor.generatePodcast({
        storyId: payload.storyId,
        audioClips,
        storySummary: story.prompt_text || story.title || 'Family Story',
        addMusic: true,
        musicStyle: 'warm',
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
      await updateStoryStatus(supabase, payload.storyId, {
        podcast_status: 'failed',
      })
      throw error
    }
  },
})

// ============================================================================
// TASK: REGENERATE PODCAST
// ============================================================================

/**
 * Regenerate podcast with new perspective
 */
export const regeneratePodcastTask = task({
  id: "regenerate-podcast",
  name: "Regenerate Story Podcast",
  version: "1.0.0",
  retry: {
    maxAttempts: 3,
    factor: 2,
    minTimeoutInMs: 1000,
    maxTimeoutInMs: 30000,
  },
  run: async (payload: RegeneratePodcastJobPayload, { ctx }) => {
    const supabase = createClient(
      process.env.SUPABASE_URL!,
      process.env.SUPABASE_KEY!
    )

    // Step 1: Update story status to 'regenerating'
    await updateStoryStatus(supabase, payload.storyId, {
      podcast_status: 'regenerating',
    })

    try {
      // Step 2: Fetch story and all responses
      const { data: story, error: storyError } = await supabase
        .from('stories')
        .select(`
          *,
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
        .eq('id', payload.storyId)
        .single()

      if (storyError || !story) {
        throw new Error(`Failed to fetch story: ${storyError?.message || 'Story not found'}`)
      }

      // Step 3: Prepare audio clips
      console.log(`Preparing audio clips for story ${payload.storyId} regeneration...`)
      const audioClips = await prepareAudioClips(supabase, story.responses || [])

      if (audioClips.length === 0) {
        throw new Error('No audio clips found for podcast regeneration')
      }

      console.log(`Regenerating podcast with ${audioClips.length} audio clips`)

      // Step 4: Initialize audio processor
      const processor = createAudioProcessor({
        ...DEFAULT_AUDIO_PROCESSOR_CONFIG,
        supabase,
      })

      // Step 5: Generate podcast
      const result = await processor.generatePodcast({
        storyId: payload.storyId,
        audioClips,
        storySummary: story.prompt_text || story.title || 'Family Story',
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
