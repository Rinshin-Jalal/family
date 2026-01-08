// src/ai/dalle.ts

import OpenAI from 'openai';
import { AIServiceError } from './types';

// ============================================================================
// DALL-E IMAGE GENERATION
// ============================================================================

export interface DalleConfig {
  apiKey: string;
  model?: 'dall-e-2' | 'dall-e-3';
  size?: '256x256' | '512x512' | '1024x1024' | '1792x1024' | '1024x1792';
  quality?: 'standard' | 'hd';
  style?: 'vivid' | 'natural';
}

export interface GenerateCoverInput {
  title: string;
  summary: string;
  style?: 'warm' | 'nostalgic' | 'playful' | 'adventurous';
}

export class DalleClient {
  private client: OpenAI;
  private config: Required<Pick<DalleConfig, 'model' | 'size' | 'quality' | 'style'>>;

  constructor(config: DalleConfig) {
    // Validate API key
    if (!config.apiKey || config.apiKey.includes('placeholder')) {
      throw new AIServiceError(
        'OPENAI_API_KEY is required for DALL-E. Set in .dev.vars for local dev or via `wrangler secret put`.',
        'dalle'
      );
    }

    this.client = new OpenAI({ apiKey: config.apiKey });

    // Default config
    this.config = {
      model: config.model || 'dall-e-3',
      size: config.size || '1024x1024',
      quality: config.quality || 'standard',
      style: config.style || 'vivid',
    };
  }

  /**
   * Generate story cover image using DALL-E
   *
   * Creates a warm, family-friendly illustration based on the story
   */
  async generateCover(input: GenerateCoverInput): Promise<{ imageUrl: string; revisedPrompt?: string }> {
    try {
      const prompt = this.buildCoverPrompt(input);

      const response = await this.client.images.generate({
        model: this.config.model,
        prompt,
        n: 1,
        size: this.config.size,
        quality: this.config.quality,
        style: this.config.style,
      });

      const imageUrl = response.data[0].url;
      const revisedPrompt = response.data[0].revised_prompt;

      if (!imageUrl) {
        throw new AIServiceError('DALL-E did not return an image URL', 'dalle');
      }

      return { imageUrl, revisedPrompt };
    } catch (error) {
      throw new AIServiceError(
        'Failed to generate cover image with DALL-E',
        'dalle',
        error
      );
    }
  }

  /**
   * Build DALL-E prompt from story input
   *
   * Creates a warm, family-friendly illustration prompt
   */
  private buildCoverPrompt(input: GenerateCoverInput): string {
    const { title, summary, style = 'warm' } = input;

    const stylePrompts = {
      warm: 'cozy, heartwarming family scene, soft warm lighting, nostalgic and emotional',
      nostalgic: 'vintage photograph style, sepia tones, nostalgic family memory, timeless and precious',
      playful: 'colorful and joyful, cartoon-style illustration, fun and energetic family moment',
      adventurous: 'dynamic action scene, exciting family adventure, vibrant colors and movement',
    };

    const basePrompt = stylePrompts[style];

    return `A beautiful book cover illustration for a family story titled "${title}". ${basePrompt}. The story is about: ${summary}. The image should be appropriate for all ages, celebrate family bonds, and have an emotional, storytelling quality. No text or typography in the image.`;
  }

  /**
   * Generate and upload cover to R2
   *
   * This generates the image, downloads it, and uploads to R2 for permanent storage
   */
  async generateAndUploadCover(
    input: GenerateCoverInput,
    storyId: string,
    r2Bucket: R2Bucket
  ): Promise<{ r2Url: string; revisedPrompt?: string }> {
    const { imageUrl, revisedPrompt } = await this.generateCover(input);

    // Download the image
    const imageResponse = await fetch(imageUrl);
    if (!imageResponse.ok) {
      throw new AIServiceError('Failed to download generated image', 'dalle');
    }

    const imageBuffer = await imageResponse.arrayBuffer();

    // Upload to R2
    const r2Key = `story-covers/${storyId}.png`;
    await r2Bucket.put(r2Key, imageBuffer, {
      httpMetadata: {
        contentType: 'image/png',
      },
    });

    // Return R2 URL (you'll need to configure your R2 public URL)
    const r2Url = `https://your-r2-domain.com/${r2Key}`;

    return { r2Url, revisedPrompt };
  }

  async healthCheck(): Promise<boolean> {
    try {
      // Simple health check - try to generate a tiny image
      const response = await this.client.images.generate({
        model: 'dall-e-2',
        prompt: 'test',
        n: 1,
        size: '256x256',
      });
      return !!response.data[0].url;
    } catch {
      return false;
    }
  }
}

export const createDalleClient = (config: DalleConfig): DalleClient => {
  return new DalleClient(config);
};
