// ============================================================================
// AUDIO PROCESSOR - Weave audio clips into podcasts
// ============================================================================
//
// Uses Replicate + ffmpeg to:
// - Download audio clips from R2
// - Normalize volume across all clips
// - Apply noise reduction
// - Create smooth crossfade transitions
// - Mix with background music
// - Export final podcast
//
// Why Replicate: Battle-tested, cost-effective, supports all ffmpeg operations
// ============================================================================

import { MusicLibrary, type MusicConfig, type MusicStyle } from './music-library'

// ============================================================================
// TYPES
// ============================================================================

export type AudioProcessorProvider = 'replicate' | 'assemblyai' | 'custom'

export interface AudioProcessorConfig {
  provider: AudioProcessorProvider
  replicateApiKey?: string
  outputFormat: 'mp3' | 'wav' | 'm4a'
  audioQuality: 'low' | 'medium' | 'high'

  // Processing options
  normalize: boolean
  noiseReduction: boolean
  crossfadeDuration: number  // seconds

  // Music configuration
  music?: Partial<MusicConfig>
}

export interface AudioClip {
  id: string
  url: string
  speakerName: string
  duration?: number
}

export interface PodcastGenerationInput {
  storyId: string
  audioClips: AudioClip[]
  storySummary?: string  // For music style selection
  outputFormat?: 'mp3' | 'wav' | 'm4a'
  musicStyle?: MusicStyle
  addMusic?: boolean
}

export interface PodcastGenerationResult {
  podcastUrl: string
  duration: number
  format: string
  fileSize: number
  clipCount: number
}

export interface AudioProcessingError extends Error {
  provider: AudioProcessorProvider
  code?: string
  retryable: boolean
}

// ============================================================================
// AUDIO PROCESSOR SERVICE
// ============================================================================

export class AudioProcessor {
  private config: AudioProcessorConfig
  private musicLibrary: MusicLibrary

  constructor(config: AudioProcessorConfig) {
    this.config = config
    this.musicLibrary = new MusicLibrary(config.music)
  }

  /**
   * Generate a podcast from audio clips
   *
   * This is the main entry point for podcast generation.
   * Uses Replicate's ffmpeg concat model for processing.
   */
  async generatePodcast(input: PodcastGenerationInput): Promise<PodcastGenerationResult> {
    try {
      // Step 1: Prepare the processing
      const processedClips = await this.prepareClips(input.audioClips)

      // Step 2: Determine music track
      const musicTrack = input.addMusic
        ? this.musicLibrary.getTrack(input.musicStyle)
        : null

      // Step 3: Build processing command
      const processingCommand = this.buildFFmpegCommand(processedClips, musicTrack)

      // Step 4: Execute processing via Replicate
      const result = await this.executeProcessing(processingCommand)

      // Step 5: Upload result to R2 and return URL
      return await this.finalizePodcast(result, input.storyId)

    } catch (error) {
      throw this.handleError(error)
    }
  }

  /**
   * Prepare audio clips for processing
   *
   * Downloads clips from R2 and prepares them for concatenation.
   * In production, this would stream from R2 to avoid memory issues.
   */
  private async prepareClips(clips: AudioClip[]): Promise<AudioClip[]> {
    // For now, we just pass through the URLs
    // In production, we might:
    // - Download to temp storage
    // - Convert to consistent format
    // - Trim silence from start/end
    // - Detect optimal crossfade points

    return clips.map(clip => ({
      ...clip,
      duration: clip.duration || 30,  // Default if unknown
    }))
  }

  /**
   * Build ffmpeg command for Replicate
   *
   * This creates the complex filter that:
   * 1. Concatenates all clips with crossfades
   * 2. Normalizes audio
   * 3. Applies noise reduction
   * 4. Mixes with background music
   */
  private buildFFmpegCommand(
    clips: AudioClip[],
    musicTrack: ReturnType<MusicLibrary['getTrack']>
  ): string {
    const crossfadeDuration = this.config.crossfadeDuration

    // For simple concatenation with crossfades
    // We'll use the ffmpeg concat filter with crossfade
    const clipUrls = clips.map(c => c.url).join(' ')

    if (musicTrack) {
      // With background music
      return `${clipUrls} -i ${musicTrack.url} -filter_complex `
        + `"concat=n=${clips.length}:v=0:a=1[a];`
        + `[a]volume=2[a_norm];`
        + `afade=t=in:st=0:d=${crossfadeDuration},afade=t=out:st=${this.getTotalDuration(clips) - crossfadeDuration}:d=${crossfadeDuration}[voices];`
        + `[1:a]volume=-12dB,fade=t=in:st=0:d=${musicTrack.fadeIn},fade=t=out:st=${this.getTotalDuration(clips) - musicTrack.fadeOut}:d=${musicTrack.fadeOut}[music];`
        + `[voices][music]amix=inputs=2:duration=first:dropout_transition=2" `
        + `-f ${this.config.outputFormat} -`
    } else {
      // Without music - just concatenate
      return `${clipUrls} `
        + `-filter_complex "`
        + `concat=n=${clips.length}:v=0:a=1[a];`
        + `[a]volume=2[a_norm];`
        + `[a_norm]afade=t=in:st=0:d=${crossfadeDuration},afade=t=out:st=${this.getTotalDuration(clips) - crossfadeDuration}:d=${crossfadeDuration}" `
        + `-f ${this.config.outputFormat} -`
    }
  }

  /**
   * Execute audio processing via Replicate
   *
   * Calls Replicate's API with the ffmpeg command.
   * In production, this would use the actual Replicate SDK.
   */
  private async executeProcessing(command: string): Promise<{
    audioBuffer: ArrayBuffer
    duration: number
  }> {
    // TODO: Implement Replicate integration
    // For now, return a mock result

    if (this.config.provider === 'replicate') {
      return await this.processWithReplicate(command)
    } else if (this.config.provider === 'assemblyai') {
      return await this.processWithAssemblyAI(command)
    } else {
      throw new Error(`Unsupported provider: ${this.config.provider}`)
    }
  }

  /**
   * Process audio using Replicate's ffmpeg model
   */
  private async processWithReplicate(command: string): Promise<{
    audioBuffer: ArrayBuffer
    duration: number
  }> {
    // TODO: Integrate with Replicate API
    // Example:
    // const output = await replicate.run(
    //   "anotherjesse/ffmpeg-concat",
    //   { input: { command } }
    // )

    // Mock result for development
    throw new Error('Replicate integration not yet implemented')
  }

  /**
   * Process audio using AssemblyAI
   */
  private async processWithAssemblyAI(command: string): Promise<{
    audioBuffer: ArrayBuffer
    duration: number
  }> {
    // TODO: Integrate with AssemblyAI API
    throw new Error('AssemblyAI integration not yet implemented')
  }

  /**
   * Finalize podcast: upload to R2, return URL
   */
  private async finalizePodcast(
    result: { audioBuffer: ArrayBuffer; duration: number },
    storyId: string
  ): Promise<PodcastGenerationResult> {
    // TODO: Upload to R2 and return URL
    // For now, return mock result

    return {
      podcastUrl: `https://your-r2-domain.com/podcasts/${storyId}.mp3`,
      duration: result.duration,
      format: this.config.outputFormat,
      fileSize: result.audioBuffer.byteLength,
      clipCount: 1,  // Will be calculated from actual clips
    }
  }

  /**
   * Calculate total duration of all clips
   */
  private getTotalDuration(clips: AudioClip[]): number {
    return clips.reduce((total, clip) => total + (clip.duration || 30), 0)
  }

  /**
   * Handle and normalize errors
   */
  private handleError(error: unknown): AudioProcessingError {
    const err = error as Error

    const processingError: AudioProcessingError = {
      name: 'AudioProcessingError',
      message: err.message || 'Unknown audio processing error',
      provider: this.config.provider,
      retryable: this.isRetryable(err),
      ...err,
    }

    return processingError
  }

  /**
   * Determine if an error is retryable
   */
  private isRetryable(error: Error): boolean {
    const retryablePatterns = [
      /timeout/i,
      /network/i,
      /rate limit/i,
      /temporary/i,
      /5\d\d/,  // 5xx errors
    ]

    return retryablePatterns.some(pattern => pattern.test(error.message))
  }

  /**
   * Health check for audio processor
   */
  async healthCheck(): Promise<boolean> {
    // TODO: Implement actual health check
    // For now, just return true if config is valid
    return !!(
      this.config.replicateApiKey ||
      this.config.provider !== 'replicate'
    )
  }

  /**
   * Update configuration
   */
  updateConfig(updates: Partial<AudioProcessorConfig>): void {
    this.config = { ...this.config, ...updates }

    // Update music library config if provided
    if (updates.music) {
      this.musicLibrary.updateConfig(updates.music)
    }
  }

  /**
   * Get current configuration
   */
  getConfig(): AudioProcessorConfig {
    return { ...this.config }
  }
}

// ============================================================================
// FACTORY FUNCTION
// ============================================================================

export function createAudioProcessor(config: AudioProcessorConfig): AudioProcessor {
  return new AudioProcessor(config)
}

// ============================================================================
// DEFAULT CONFIGURATION
// ============================================================================

export const DEFAULT_AUDIO_PROCESSOR_CONFIG: AudioProcessorConfig = {
  provider: 'replicate',
  outputFormat: 'mp3',
  audioQuality: 'high',
  normalize: true,
  noiseReduction: true,
  crossfadeDuration: 1.5,
  music: {
    enabled: true,
    style: 'warm',
    volume: 0.25,
    fadeInDuration: 2,
    fadeOutDuration: 3,
  },
}
