// src/ai/cartesia.ts

import {
  TranscribeResult,
  AIServiceError
} from './types';

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