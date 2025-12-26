// ============================================================================
// MUSIC LIBRARY - Background music for podcasts
// ============================================================================
//
// Manages royalty-free background music tracks for story podcasts.
// Music is stored in R2 and selected based on story mood.
//
// Music sources:
// - Pixabay Music (free, no attribution)
// - Unminus (free, curated)
// - Custom uploads
//
// Usage: Download tracks from Pixabay, upload to R2 bucket under /music/
// ============================================================================

export type MusicStyle = 'warm' | 'nostalgic' | 'uplifting' | 'gentle' | 'playful'

export interface MusicTrack {
  id: string
  name: string
  style: MusicStyle
  url: string
  duration: number
  fadeIn: number
  fadeOut: number
}

export interface MusicConfig {
  enabled: boolean
  style: MusicStyle
  volume: number  // 0.0 to 1.0, recommend 0.2-0.3 for background
  fadeInDuration: number  // seconds
  fadeOutDuration: number  // seconds
}

// ============================================================================
// MUSIC LIBRARY
// ============================================================================

/**
 * Pre-configured music tracks
 *
 * These are URLs pointing to R2 storage where music files are stored.
 * To add music:
 * 1. Download from Pixabay Music (https://pixabay.com/music/)
 * 2. Upload to R2 bucket: /music/{filename}.mp3
 * 3. Add entry below
 */
export const MUSIC_LIBRARY: Record<MusicStyle, MusicTrack[]> = {
  warm: [
    {
      id: 'warm-piano-1',
      name: 'Warm Piano Emotions',
      style: 'warm',
      url: 'https://your-r2-domain.com/music/warm-piano-1.mp3',
      duration: 180,  // 3 minutes
      fadeIn: 2,
      fadeOut: 3,
    },
    {
      id: 'warm-acoustic-1',
      name: 'Gentle Acoustic',
      style: 'warm',
      url: 'https://your-r2-domain.com/music/warm-acoustic-1.mp3',
      duration: 240,  // 4 minutes
      fadeIn: 2,
      fadeOut: 3,
    },
  ],

  nostalgic: [
    {
      id: 'nostalgic-strings-1',
      name: 'Nostalgic Strings',
      style: 'nostalgic',
      url: 'https://your-r2-domain.com/music/nostalgic-strings-1.mp3',
      duration: 200,
      fadeIn: 3,
      fadeOut: 4,
    },
    {
      id: 'nostalgic-piano-1',
      name: 'Memory Lane',
      style: 'nostalgic',
      url: 'https://your-r2-domain.com/music/nostalgic-piano-1.mp3',
      duration: 180,
      fadeIn: 2,
      fadeOut: 3,
    },
  ],

  uplifting: [
    {
      id: 'uplifting-acoustic-1',
      name: 'Bright Morning',
      style: 'uplifting',
      url: 'https://your-r2-domain.com/music/uplifting-acoustic-1.mp3',
      duration: 180,
      fadeIn: 2,
      fadeOut: 3,
    },
  ],

  gentle: [
    {
      id: 'gentle-ambient-1',
      name: 'Gentle Ambient',
      style: 'gentle',
      url: 'https://your-r2-domain.com/music/gentle-ambient-1.mp3',
      duration: 240,
      fadeIn: 3,
      fadeOut: 4,
    },
  ],

  playful: [
    {
      id: 'playful-ukulele-1',
      name: 'Playful Ukulele',
      style: 'playful',
      url: 'https://your-r2-domain.com/music/playful-ukulele-1.mp3',
      duration: 150,
      fadeIn: 1,
      fadeOut: 2,
    },
  ],
}

// ============================================================================
// MUSIC LIBRARY SERVICE
// ============================================================================

export class MusicLibrary {
  private config: MusicConfig

  constructor(config?: Partial<MusicConfig>) {
    this.config = {
      enabled: true,
      style: 'warm',
      volume: 0.25,
      fadeInDuration: 2,
      fadeOutDuration: 3,
      ...config,
    }
  }

  /**
   * Get a music track for the given style
   * Randomly selects from available tracks
   */
  getTrack(style?: MusicStyle): MusicTrack | null {
    if (!this.config.enabled) {
      return null
    }

    const trackStyle = style || this.config.style
    const tracks = MUSIC_LIBRARY[trackStyle]

    if (!tracks || tracks.length === 0) {
      return null
    }

    // Random selection for variety
    const index = Math.floor(Math.random() * tracks.length)
    return tracks[index]
  }

  /**
   * Get all tracks for a style
   */
  getTracksByStyle(style: MusicStyle): MusicTrack[] {
    return MUSIC_LIBRARY[style] || []
  }

  /**
   * Get music configuration
   */
  getConfig(): MusicConfig {
    return { ...this.config }
  }

  /**
   * Update music configuration
   */
  updateConfig(updates: Partial<MusicConfig>): void {
    this.config = { ...this.config, ...updates }
  }

  /**
   * Build ffmpeg audio filter for mixing music with voice
   *
   * This creates a filter that:
   * 1. Lowers music volume to background level
   * 2. Fades music in at start
   * 3. Fades music out at end
   * 4. Mixes with voice track
   */
  buildFFmpegFilter(podcastDuration: number): string {
    if (!this.config.enabled) {
      return ''
    }

    const track = this.getTrack()
    if (!track) {
      return ''
    }

    // Volume in decibels (0.25 = -12dB)
    const volumeDb = -12
    const fadeIn = this.config.fadeInDuration
    const fadeOut = this.config.fadeOutDuration

    // Build filter complex
    // [1:a] = music input
    // [0:a] = voice input
    return `[1:a]volume=${volumeDb}dB,fade=t=in:st=0:d=${fadeIn},fade=t=out:st=${podcastDuration - fadeOut}:d=${fadeOut}[bg];[0:a][bg]amix=inputs=2:duration=first:dropout_transition=2`
  }

  /**
   * Get recommended music style based on story content
   *
   * This is a simple heuristic - could be enhanced with AI analysis
   */
  recommendStyle(storySummary: string): MusicStyle {
    const summary = storySummary.toLowerCase()

    if (summary.includes('child') || summary.includes('fun') || summary.includes('play')) {
      return 'playful'
    }

    if (summary.includes('remember') || summary.includes('memories') || summary.includes('old')) {
      return 'nostalgic'
    }

    if (summary.includes('sad') || summary.includes('loss') || summary.includes('miss')) {
      return 'gentle'
    }

    if (summary.includes('happy') || summary.includes('excited') || summary.includes('celebrate')) {
      return 'uplifting'
    }

    // Default to warm
    return 'warm'
  }
}

// ============================================================================
// FACTORY FUNCTION
// ============================================================================

export function createMusicLibrary(config?: Partial<MusicConfig>): MusicLibrary {
  return new MusicLibrary(config)
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/**
 * Parse music style from string
 */
export function parseMusicStyle(style: string): MusicStyle | null {
  const validStyles: MusicStyle[] = ['warm', 'nostalgic', 'uplifting', 'gentle', 'playful']
  if (validStyles.includes(style as MusicStyle)) {
    return style as MusicStyle
  }
  return null
}

/**
 * Validate music track URL
 */
export function isValidMusicUrl(url: string): boolean {
  return url.startsWith('https://') || url.startsWith('http://')
}
