// src/ai/cartesia.ts

import {
  TranscribeResult,
  AIServiceError
} from './types';

// ============================================================================
// CARTESIA TTS CONFIGURATION
// ============================================================================

export interface CartesiaVoice {
  id: string;
  name: string;
  description?: string;
  language: string;
  gender?: 'male' | 'female' | 'neutral';
}

export interface TTSConfig {
  voice?: CartesiaVoice;
  outputFormat?: 'mp3' | 'wav';
  sampleRate?: number;
}

export interface TTSResult {
  audioBuffer: ArrayBuffer;
  duration: number;
  format: string;
}

// Default voice options for different user types (using real Cartesia Sonic-3 voice IDs)
export const DEFAULT_VOICES: Record<string, CartesiaVoice> = {
  narrator: {
    id: 'f786b574-daa5-4673-aa0c-cbe3e8534c02', // Katie - stable, realistic voice
    name: 'Katie',
    description: 'Neutral storytelling voice - stable and realistic',
    language: 'en',
    gender: 'female'
  },
  male: {
    id: '228fca29-3a0a-435c-8728-5cb483251068', // Kiefer - stable male voice
    name: 'Kiefer',
    description: 'Stable male voice for voice agents',
    language: 'en',
    gender: 'male'
  },
  female: {
    id: '6ccbfb76-1fc6-48f7-b71d-91ac6298247b', // Tessa - emotive female voice
    name: 'Tessa',
    description: 'Expressive and emotive female voice',
    language: 'en',
    gender: 'female'
  }
};

// Cartesia TTS model constants
export const CARTESIA_TTS_MODEL = 'sonic-3'; // Latest streaming TTS model
export const CARTESIA_API_VERSION = '2025-04-16';

// ============================================================================
// CARTESIA INK CLIENT (REST API - No WebSocket Needed)
// ============================================================================

export interface CartesiaConfig {
  apiKey: string;
  baseUrl?: string;
}

export class CartesiaClient {
  private config: CartesiaConfig;
  private baseUrl: string;

  constructor(config: CartesiaConfig) {
    // Validate API key is provided
    if (!config.apiKey || config.apiKey.includes('placeholder')) {
      throw new AIServiceError(
        'CARTESIA_API_KEY is required. Set in .dev.vars for local dev or via `wrangler secret put` for production.',
        'cartesia'
      );
    }

    this.config = {
      baseUrl: 'https://api.cartesia.ai',
      ...config
    };
    this.baseUrl = this.config.baseUrl!;
  }

    /**
     * Transcribe audio buffer using Cartesia Ink (REST API)
     * 
     * WHY REST API: Simpler than WebSocket for one-off transcription.
     * Just upload and wait for result - no state management needed.
     */
    async transcribeAudio(audioBuffer: ArrayBuffer): Promise<TranscribeResult> {
      const startTime = Date.now();

      try {
        // 1. Upload audio file to Cartesia
        const formData = new FormData();
        const audioFile = new File([audioBuffer], 'audio.mp3', { type: 'audio/mpeg' });

        formData.append('audio', audioFile);
        formData.append('model', 'ink'); // Cartesia Ink model (fast & accurate)
        formData.append('language', 'en'); // Default to English
        formData.append('response_format', 'verbose_json'); // Get duration

        const response = await fetch(`${this.baseUrl}/v1/transcribe`, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${this.config.apiKey}`,
          },
          body: formData,
        });

        if (!response.ok) {
          const errorText = await response.text();
          throw new AIServiceError(
            `Cartesia API error: ${response.status} - ${errorText}`,
            'cartesia',
            errorText
          );
        }

        // 2. Parse response
        const data = await response.json() as { text: string; duration: number };

        // 3. Extract text and duration
        const text = data.text ?? '';
        const duration = data.duration ?? (Date.now() - startTime) / 1000;

        return {
          text,
          duration_seconds: duration,
        };
      } catch (error) {
        if (error instanceof AIServiceError) {
          throw error;
        }
        throw new AIServiceError(
          'Failed to transcribe audio with Cartesia',
          'cartesia',
          error
        );
      }
    }

    /**
     * Convert text to speech using Cartesia Sonic-3 TTS
     *
     * This endpoint generates audio from text using the Sonic-3 model.
     * Returns audio bytes that can be saved or streamed.
     */
    async textToSpeech(
      text: string,
      config: TTSConfig = {}
    ): Promise<TTSResult> {
      const startTime = Date.now();

      try {
        // Use narrator voice by default
        const voice = config.voice || DEFAULT_VOICES.narrator;
        const outputFormat = config.outputFormat || 'mp3';
        const sampleRate = config.sampleRate || 24000; // Cartesia default

        // Build request body for Cartesia TTS API
        const requestBody = {
          model_id: CARTESIA_TTS_MODEL,
          voice: {
            id: voice.id,
            // Optional: Add voice settings if needed
          },
          transcript: text,
          output_format: {
            container: outputFormat,
            sample_rate: sampleRate,
            encoding: 'pcm_s16le' // 16-bit PCM
          },
          language: voice.language || 'en',
          // Optional: Add speed control
          // speed: 'normal'
        };

        // Call Cartesia TTS endpoint
        const response = await fetch(`${this.baseUrl}/tts/bytes`, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${this.config.apiKey}`,
            'Cartesia-Version': CARTESIA_API_VERSION,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(requestBody),
        });

        if (!response.ok) {
          const errorText = await response.text();
          throw new AIServiceError(
            `Cartesia TTS API error: ${response.status} - ${errorText}`,
            'cartesia',
            errorText
          );
        }

        // Get audio buffer from response
        const audioBuffer = await response.arrayBuffer();

        // Estimate duration (rough calculation based on text length and avg speaking rate)
        const wordsPerSecond = 2.5; // Average speaking rate
        const wordCount = text.split(/\s+/).length;
        const duration = wordCount / wordsPerSecond;

        return {
          audioBuffer,
          duration,
          format: outputFormat
        };
      } catch (error) {
        if (error instanceof AIServiceError) {
          throw error;
        }
        throw new AIServiceError(
          'Failed to generate speech with Cartesia TTS',
          'cartesia',
          error
        );
      }
    }

    /**
     * Health check for Cartesia API
     */
    async healthCheck(): Promise<boolean> {
      try {
        const response = await fetch(`${this.baseUrl}/v1/health`, {
          method: 'GET',
          headers: {
            'Authorization': `Bearer ${this.config.apiKey}`,
          },
        });
        return response.ok;
      } catch {
        return false;
      }
    }
  }

  // ============================================================================
  // FACTORY FUNCTION
  // ============================================================================

  export const createCartesiaClient = (config: CartesiaConfig): CartesiaClient => {
    return new CartesiaClient(config);
  };