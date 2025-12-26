     // src/ai/types.ts

     // ============================================================================
     // SHARED TYPES FOR ALL AI SERVICES
     // ============================================================================

     // -----------------------
     // LLM (Qwen-Turbo via Bedrock) Types
     // -----------------------

     export interface StorySegment {
      order_index: number;
      response_id: string;
      speaker_name: string;
      speaker_role: 'elder' | 'organizer' | 'member' | 'child';
      speaker_age: number;
      dialogue_snippet: string;
    }

    export interface StorySynthesisResult {
      title: string;
      summary: string;
      segments: StorySegment[];
    }

    // -----------------------
    // Audio (Cartesia Ink) Types
    // -----------------------

    export interface TranscribeResult {
      text: string;
      duration_seconds: number;
    }

    // -----------------------
    // Image (Replicate SDXL) Types
    // -----------------------

    export interface ImageGenerationResult {
      image_url: string;
      revised_prompt: string;
    }

    export interface StoryCoverRequest {
      family_name: string;
      story_theme: string;
      family_count: number;
    }

    export interface StoryPanelRequest {
      speaker_name: string;
      speaker_age: number;
      speaker_role: 'elder' | 'organizer' | 'member' | 'child';
      dialogue_snippet: string;
      panel_index: number;
    }

    // -----------------------
    // Model Configuration Types
    // -----------------------

    export type LLMProvider = 'qwen-turbo' | 'kimi-k2' | 'minimax' | 'claude-3.5';

    export type ImageProvider = 'stable-diffusion-xl' | 'dall-e-3' | 'qwen-vl' | 'xai-grok';

    // -----------------------
    // Error Types
    // -----------------------

    export class AIServiceError extends Error {
      constructor(
        message: string,
        public service: string,
        public originalError?: unknown
      ) {
        super(message);
        this.name = 'AIServiceError';
      }
    }

    export interface RetryConfig {
      maxAttempts: number;
      initialDelayMs: number;
      backoffMultiplier: number;
    }