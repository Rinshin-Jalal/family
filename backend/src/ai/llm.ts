// src/ai/llm.ts

import OpenAI from 'openai';
import {
  StorySynthesisResult,
  StorySegment,
  AIServiceError
} from './types';

// ============================================================================
// QWEN-TURBO VIA BEDROCK USING OPENAI SDK
// ============================================================================

export interface QwenTurboConfig {
  openaiApiKey: string;
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
  private client: OpenAI;
  private modelId: string;

  constructor(config: QwenTurboConfig) {
    this.modelId = config.modelId || 'openai.gpt-oss-safeguard-120b';

    // Use OpenAI SDK to call AWS Bedrock (OpenAI-compatible endpoint)
    this.client = new OpenAI({
      apiKey: config.openaiApiKey,
      baseURL: `https://bedrock-runtime.us-west-2.amazonaws.com/openai/v1`,
      defaultQuery: undefined,
    });
  }

  async synthesizeStory(input: SynthesizeStoryInput): Promise<StorySynthesisResult> {
    try {
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
1. Keep title under 60 characters, heartwarming and specific
2. Summarize in 2-3 sentences that weave together all perspectives
3. For each response, extract a "narrative_segment" for image generation
4. Map responses to the exact order they were shared
5. Preserve the emotional essence of each speaker
6. Return ONLY valid JSON, no markdown

Response format example:
{
  "title": "Grandma's Road Trip Memory",
  "summary": "Grandma recalls driving across the country in a Chevy, while Dad lovingly corrects that it was actually a Ford with a blown tire in Nevada.",
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
}`;

      const response = await this.client.chat.completions.create({
        model: this.modelId,
        messages: [
          {
            role: 'system',
            content: systemPrompt,
          },
          {
            role: 'user',
            content: `Here are transcribed responses from a family story session about "${input.promptText}":\n\n${responsesText}\n\nAnalyze these responses and
return a JSON object with:\n  1. title (string, max 60 chars) - Heartwarming and specific to the story\n  2. summary (string, max 300 chars) - 2-3 sentences weaving
 together all perspectives\n  3. segments (array of objects, one per response):\n     - order_index (integer, starting from 1, matches response order)\n     -
response_id (string, exactly match the input response IDs)\n     - speaker_name (string, name from transcription)\n     - speaker_role (string:
elder/organizer/member/child)\n     - speaker_age (integer, estimate based on role)\n     - dialogue_snippet (string, max 50 chars, extract key quote for image
prompt)\n\nReturn ONLY valid JSON, no markdown formatting.`,
          },
        ],
        temperature: 0.7,
        max_tokens: 2000,
        response_format: { type: 'json_object' },
      });

      return this.parseStorySynthesisResponse(response);
    } catch (error) {
      throw new AIServiceError(
        'Failed to synthesize story with Qwen-Turbo',
        'qwen-turbo',
        error
      );
    }
  }

  private parseStorySynthesisResponse(response: any): StorySynthesisResult {
    try {
      const content = response.choices[0].message.content;
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

  private getSpeakerAge(role: string): number {
    const ageMap: Record<string, number> = {
      elder: 75,
      organizer: 42,
      member: 35,
      child: 8,
    };
    return ageMap[role] || 30;
  }

  async healthCheck(): Promise<boolean> {
    try {
      await this.client.chat.completions.create({
        model: this.modelId,
        messages: [{ role: 'user', content: 'ping' }],
        max_tokens: 5,
      });
      return true;
    } catch {
      return false;
    }
  }
}

export const createQwenTurboClient = (config: QwenTurboConfig): QwenTurboClient => {
  return new QwenTurboClient(config);
};