// src/ai/llm.ts

import {
  StorySynthesisResult,
  StorySegment,
  AIServiceError
} from './types';

// ============================================================================
// AWS SIGNATURE V4 HELPER (No SDK - Pure Implementation)
// ============================================================================

const AWS_SIGV4_ALGORITHM = 'AWS4-HMAC-SHA256';
const AWS_SERVICE = 'bedrock-runtime';
const AWS_REQUEST_TYPE = 'aws4_request';

async function sha256(message: string): Promise<string> {
  // In Cloudflare Workers, use crypto.subtle
  const encoder = new TextEncoder();
  const data = encoder.encode(message);
  return await crypto.subtle.digest('SHA-256', data).then(hash => {
    return Array.from(new Uint8Array(hash))
      .map(b => b.toString(16).padStart(2, '0'))
      .join('');
  });
}

async function getSignatureKey(
  key: string,
  date: string,
  region: string,
  service: string
): Promise<ArrayBuffer> {
  const kDate = await hmacSha256(`AWS4${key}`, date);
  const kRegion = await hmacSha256(kDate, region);
  const kService = await hmacSha256(kRegion, service);
  const kSigning = await hmacSha256(kService, AWS_REQUEST_TYPE);
  return kSigning;
}

async function hmacSha256(key: string | ArrayBuffer, message: string): Promise<ArrayBuffer> {
  const encoder = new TextEncoder();
  const keyBytes = typeof key === 'string'
    ? encoder.encode(key)
    : new Uint8Array(key);
  const messageBytes = encoder.encode(message);

  const cryptoKey = await crypto.subtle.importKey(
    'raw',
    keyBytes,
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );

  return crypto.subtle.sign('HMAC', cryptoKey, messageBytes);
}

async function signRequest(
  accessKeyId: string,
  secretAccessKey: string,
  region: string,
  method: string,
  path: string,
  body: string,
  timestamp: string
): Promise<{ authorization: string; xAmzDate: string }> {
  const host = `bedrock-runtime.${region}.amazonaws.com`;
  const xAmzDate = timestamp;

  // 1. Canonical Request
  const canonicalHeaders = `host:${host}\nx-amz-date:${xAmzDate}\n`;
  const signedHeaders = 'host;x-amz-date';
  const payloadHash = await sha256(body);

  const canonicalRequest = [
    method,
    path,
    '',
    canonicalHeaders,
    signedHeaders,
    payloadHash
  ].join('\n');

  // 2. String to Sign
  const dateStamp = timestamp.slice(0, 8);
  const credentialScope = `${dateStamp}/${region}/${AWS_SERVICE}/${AWS_REQUEST_TYPE}`;
  const canonicalRequestHash = await sha256(canonicalRequest);

  const stringToSign = [
    AWS_SIGV4_ALGORITHM,
    timestamp,
    credentialScope,
    canonicalRequestHash
  ].join('\n');

  // 3. Calculate Signature
  const signingKey = await getSignatureKey(secretAccessKey, dateStamp, region, AWS_SERVICE);
  const signatureBuffer = await crypto.subtle.sign(
    'HMAC',
    await crypto.subtle.importKey('raw', signingKey, { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']),
    new TextEncoder().encode(stringToSign)
  );
  const signature = Array.from(new Uint8Array(signatureBuffer))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');

  // 4. Authorization Header
  const authorization = [
    `${AWS_SIGV4_ALGORITHM} Credential=${accessKeyId}/${credentialScope}`,
    `SignedHeaders=${signedHeaders}`,
    `Signature=${signature}`
  ].join(', ');

  return { authorization, xAmzDate };
}

// ============================================================================
// QWEN-TURBO VIA BEDROCK CLIENT
// ============================================================================

export interface QwenTurboConfig {
  accessKeyId: string;
  secretAccessKey: string;
  region: string;
  modelId?: string;
}

export interface SynthesizeStoryInput {
  responses: Array<{
    id: string;
    transcription_text: string;
    profiles: {
      full_name: string;
      role: 'elder' | 'organizer' | 'member' | 'child';
      avatar_url?: string;
    };
  }>;
  promptText: string;
}

export class QwenTurboClient {
  private config: QwenTurboConfig;
  private baseUrl: string;

  constructor(config: QwenTurboConfig) {
    this.config = {
      modelId: 'qwen-turbo-v1', // Default Qwen model in Bedrock
      ...config
    };
    this.baseUrl = `https://bedrock-runtime.${this.config.region}.amazonaws.com`;
  }

  /**
   * Synthesize a family story from multiple responses using Qwen-Turbo
   */
  async synthesizeStory(input: SynthesizeStoryInput): Promise<StorySynthesisResult> {
    const timestamp = new Date().toISOString().replace(/[:\-]|\.\d{3}/g, '');
    const body = JSON.stringify(this.buildStorySynthesisPrompt(input));

    // Sign request with AWS SigV4
    const { authorization, xAmzDate } = await signRequest(
      this.config.accessKeyId,
      this.config.secretAccessKey,
      this.config.region,
      'POST',
      '/v1/chat/completions',
      body,
      timestamp
    );

    // Make HTTP request to Bedrock
    const response = await fetch(`${this.baseUrl}/v1/chat/completions`, {
      method: 'POST',
      headers: {
        'Authorization': authorization,
        'X-Amz-Date': xAmzDate,
        'Content-Type': 'application/json',
        'Host': `bedrock-runtime.${this.config.region}.amazonaws.com`,
      },
      body,
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new AIServiceError(
        `Qwen-Turbo API error: ${response.status} - ${errorText}`,
        'qwen-turbo',
        errorText
      );
    }

    const data = await response.json();

    // Parse structured JSON response
    return this.parseStorySynthesisResponse(data);
  }

  /**
   * Build the story synthesis prompt for Qwen-Turbo
   */
  private buildStorySynthesisPrompt(input: SynthesizeStoryInput): any {
    // Format responses for the prompt
    const responsesText = input.responses
      .map((r, idx) => {
        const speakerRole = r.profiles.role;
        const speakerName = r.profiles.full_name;
        const age = this.getSpeakerAge(speakerRole);

        return `[${idx + 1}] ${speakerName} (${speakerRole}, ${age} years old): "${r.transcription_text}"`;
      })
      .join('\n');

    const systemPrompt = `You are an empathetic family story weaver. You receive multiple audio transcriptions from different family members (with corrections, 
additions, and debates). Your job is to synthesize these into a cohesive, warm "StoryRide" that honors all perspectives while creating a narrative arc.

    Rules:
    1. Keep the title under 60 characters, heartwarming and specific
    2. Summarize in 2-3 sentences that weave together all perspectives
    3. For each response, extract a "narrative_segment" for image generation
    4. Map responses to the exact order they were shared
    5. Preserve the emotional essence of each speaker
    6. Return ONLY valid JSON, no markdown`;

    return {
      model: this.config.modelId,
      messages: [
        {
          role: 'system',
          content: systemPrompt,
        },
        {
          role: 'user',
          content: `Here are transcribed responses from a family story session about "${input.promptText}":\n\n${responsesText}\n\nAnalyze these responses and
return a JSON object with:
  1. title (string, max 60 chars)
  2. summary (string, max 300 chars)
  3. segments (array of objects with):
     - order_index (integer, starting from 1)
     - response_id (string, match to input responses)
     - speaker_name (string)
     - speaker_role (string: elder/organizer/member/child)
     - speaker_age (integer)
     - dialogue_snippet (string, max 50 chars for image prompt)

Response format example:
{
  "title": "Grandma's Road Trip Memory",
  "summary": "Grandma recalls driving across the country in a Chevy, while Dad corrects that it was actually a Ford with a blown tire in Nevada.",
  "segments": [
    {
      "order_index": 1,
      "response_id": "uuid-1",
      "speaker_name": "Grandma",
      "speaker_role": "elder",
      "speaker_age": 75,
      "dialogue_snippet": "driving across country in a Chevy"
    },
    {
      "order_index": 2,
      "response_id": "uuid-2",
      "speaker_name": "Dad",
      "speaker_role": "organizer",
      "speaker_age": 42,
      "dialogue_snippet": "blown tire in Nevada"
    }
  ]
}`,
        },
      ],
      temperature: 0.7,
      max_tokens: 2000,
      response_format: { type: 'json_object' },
    };
  }

  /**
   * Parse Qwen-Turbo response into StorySynthesisResult
   */
  private parseStorySynthesisResponse(data: any): StorySynthesisResult {
    try {
      const content = data.choices[0].message.content;
      const parsed = JSON.parse(content);

      return {
        title: parsed.title,
        summary: parsed.summary,
        segments: parsed.segments.map((seg: any) => ({
          order_index: seg.order_index,
          response_id: seg.response_id,
          speaker_name: seg.speaker_name,
          speaker_role: seg.speaker_role,
          speaker_age: seg.speaker_age,
          dialogue_snippet: seg.dialogue_snippet,
        })),
      };
    } catch (error) {
      throw new AIServiceError(
        'Failed to parse Qwen-Turbo response as JSON',
        'qwen-turbo',
        error
      );
    }
  }

  /**
   * Get estimated age for speaker role (for image prompts)
   */
  private getSpeakerAge(role: string): number {
    const ageMap: Record<string, number> = {
      elder: 75,
      organizer: 42,
      member: 35,
      child: 8,
    };
    return ageMap[role] || 30;
  }

  /**
   * Test connection to Bedrock
   */
  async healthCheck(): Promise<boolean> {
    try {
      const response = await fetch(`${this.baseUrl}/v1/models`, {
        method: 'GET',
        headers: {
          'Authorization': `AWS4-HMAC-SHA256 Credential=${this.config.accessKeyId}/20240101/${this.config.region}/bedrock-runtime/aws4_request`,
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

export const createQwenTurboClient = (config: QwenTurboConfig): QwenTurboClient => {
  return new QwenTurboClient(config);
};