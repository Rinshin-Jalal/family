// ============================================================================
// SEMANTIC EMBEDDINGS MODULE
// Generates and stores vector embeddings for semantic search using pgvector
// Uses AWS Bedrock with AWS SDK v3 for proper SigV4 authentication
// ============================================================================

import { BedrockRuntimeClient, InvokeModelCommand } from '@aws-sdk/client-bedrock-runtime';
import { AIServiceError } from './types';

// Configuration
export interface EmbeddingsConfig {
  accessKeyId?: string;
  secretAccessKey?: string;
  sessionToken?: string;
  region?: string;
  modelId?: string;
}

export interface EmbeddingResult {
  embedding: number[];
  usage: {
    promptTokens: number;
    totalTokens: number;
  };
}

// Embedding dimensions for AWS Bedrock Titan models
export const EMBEDDING_MODELS = {
  'amazon.titan-embed-text-v2': 1024,  // Titan v2 (default)
  'amazon.titan-embed-text-v1': 1536,  // Titan v1
  'cohere.embed-english-v3': 1024,      // Cohere English
  'cohere.embed-multilingual-v3': 1024, // Cohere Multilingual
} as const;

export type EmbeddingModel = keyof typeof EMBEDDING_MODELS;

export class EmbeddingsClient {
  private client: BedrockRuntimeClient;
  private modelId: string;
  private dimensions: number;

  constructor(config: EmbeddingsConfig) {
    // Use AWS Titan Embeddings v2 by default
    this.modelId = config.modelId || 'amazon.titan-embed-text-v2';
    this.dimensions = EMBEDDING_MODELS[this.modelId as EmbeddingModel] || 1024;

    // Create AWS credentials from environment or config
    const region = config.region || 'us-east-1';

    // Get credentials from environment or config (for Cloudflare Workers/trigger.dev)
    const accessKeyId = config.accessKeyId || process.env.AWS_ACCESS_KEY_ID;
    const secretAccessKey = config.secretAccessKey || process.env.AWS_SECRET_ACCESS_KEY;
    const sessionToken = config.sessionToken || process.env.AWS_SESSION_TOKEN;

    if (!accessKeyId || !secretAccessKey) {
      throw new Error('AWS credentials (AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY) are required');
    }

    this.client = new BedrockRuntimeClient({
      region,
      credentials: {
        accessKeyId,
        secretAccessKey,
        ...(sessionToken && { sessionToken }),
      },
    });

    console.log(`[Embeddings] Initialized with model: ${this.modelId}, dims: ${this.dimensions}, region: ${region}`);
  }

  /**
   * Generate embedding using AWS Bedrock native API
   */
  async embed(text: string): Promise<EmbeddingResult> {
    try {
      console.log(`[Embeddings] Calling Bedrock: ${this.modelId}`);
      console.log(`[Embeddings] Input text length: ${text.length} chars`);

      // AWS Bedrock native API format for embeddings
      const command = new InvokeModelCommand({
        modelId: this.modelId,
        contentType: 'application/json',
        accept: 'application/json',
        body: JSON.stringify({
          inputText: text,
        }),
      });

      const response = await this.client.send(command);

      // Parse response
      const data = JSON.parse(new TextDecoder().decode(response.body));

      console.log(`[Embeddings] Response keys:`, Object.keys(data));

      // AWS Bedrock Titan response format
      const embedding = data.embedding;
      const inputTokenCount = data.inputTextTokenCount || 0;

      if (!embedding || !Array.isArray(embedding)) {
        console.error(`[Embeddings] Invalid embedding in response:`, data);
        throw new Error('Invalid embedding response from Bedrock');
      }

      console.log(`[Embeddings] ✅ Generated ${embedding.length} dims, ${inputTokenCount} tokens`);

      return {
        embedding,
        usage: {
          promptTokens: inputTokenCount,
          totalTokens: inputTokenCount,
        },
      };
    } catch (error) {
      console.error('[Embeddings] Error generating embedding:', error);
      throw new AIServiceError(
        'Failed to generate embedding',
        'embeddings',
        error
      );
    }
  }

  /**
   * Generate embeddings for multiple texts in batch
   * Note: AWS Bedrock Titan does not support batching in a single request
   * This method makes parallel requests for better performance
   */
  async embedBatch(texts: string[]): Promise<EmbeddingResult[]> {
    try {
      console.log(`[Embeddings] Batch processing ${texts.length} texts...`);

      // Process in parallel (Titan doesn't support true batching)
      const promises = texts.map((text) => this.embed(text));
      const results = await Promise.all(promises);

      console.log(`[Embeddings] ✅ Batch complete: ${results.length} embeddings`);
      return results;
    } catch (error) {
      console.error('[Embeddings] Error generating batch embeddings:', error);
      throw new AIServiceError(
        'Failed to generate batch embeddings',
        'embeddings',
        error
      );
    }
  }

  /**
   * Generate embedding and format as PostgreSQL vector literal
   * Format: '[0.1, 0.2, ...]'
   */
  async embedForPostgres(text: string): Promise<string> {
    const result = await this.embed(text);
    return '[' + result.embedding.join(', ') + ']';
  }

  /**
   * Health check
   */
  async healthCheck(): Promise<boolean> {
    try {
      await this.embed('health check');
      return true;
    } catch {
      return false;
    }
  }

  /**
   * Get model info
   */
  getModelInfo() {
    return {
      modelId: this.modelId,
      dimensions: this.dimensions,
    };
  }
}

/**
 * Create client
 */
export function createEmbeddingsClient(config: EmbeddingsConfig): EmbeddingsClient {
  return new EmbeddingsClient(config);
}

/**
 * Format embedding as PostgreSQL vector literal for INSERT/UPDATE
 */
export function formatEmbeddingForPostgres(embedding: number[]): string {
  // Round to 6 decimal places to save space and reduce DB size
  const rounded = embedding.map(v => Math.round(v * 1e6) / 1e6);
  return '[' + rounded.join(', ') + ']';
}

/**
 * Parse PostgreSQL vector literal to number array
 */
export function parseEmbeddingFromPostgres(pgVector: string): number[] {
  // Remove brackets and split by comma
  const cleaned = pgVector.replace('[', '').replace(']', '');
  return cleaned.split(',').map(Number);
}

/**
 * Default embedding text for a story (combines title + summary)
 */
export function storyToEmbeddingText(story: {
  title: string | null;
  summary_text: string | null;
}): string {
  const parts: string[] = [];
  
  if (story.title) {
    parts.push(story.title);
  }
  if (story.summary_text) {
    parts.push(story.summary_text);
  }
  
  return parts.join(' ').trim();
}

/**
 * Default embedding text for a quote
 */
export function quoteToEmbeddingText(quote: {
  quote_text: string;
  author_name: string | null;
}): string {
  const parts: string[] = [];
  
  parts.push(quote.quote_text);
  
  if (quote.author_name) {
    parts.push(`- ${quote.author_name}`);
  }
  
  return parts.join(' ').trim();
}
