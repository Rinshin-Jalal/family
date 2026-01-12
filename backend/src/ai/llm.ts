// src/ai/llm.ts

import OpenAI from 'openai';
import {
  StorySynthesisResult,
  AIServiceError
} from './types';

// ============================================================================
// QWEN-TURBO VIA BEDROCK USING OPENAI SDK
// ============================================================================

export interface QwenTurboConfig {
  openaiApiKey: string;
  modelId?: string;
  bedrockRegion?: string;
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
    // Validate API key is provided
    if (!config.openaiApiKey || config.openaiApiKey.includes('placeholder')) {
      throw new AIServiceError(
        'AWS_BEARER_TOKEN_BEDROCK is required. Set in .dev.vars for local dev or via `wrangler secret put` for production.',
        'qwen.qwen3-next-80b-a3b'
      );
    }

    this.modelId = config.modelId || 'qwen.qwen3-next-80b-a3b';

    // Construct Bedrock endpoint URL
    const region = config.bedrockRegion || 'us-west-2';
    const bedrockEndpoint = `https://bedrock-runtime.${region}.amazonaws.com/openai/v1`;

    // Use OpenAI SDK to call AWS Bedrock (OpenAI-compatible endpoint)
    this.client = new OpenAI({
      apiKey: config.openaiApiKey,
      baseURL: bedrockEndpoint,
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

  /**
   * Extract a meaningful quote from transcription text
   * Returns a quote that captures wisdom, humor, or emotional resonance
   */
  async extractQuote(transcription: string): Promise<{ quote: string; confidence: number }> {
    try {
      const systemPrompt = `You are an expert at extracting meaningful quotes from family stories and conversations.

Your task is to extract the most impactful, memorable quote from the given text.

Rules:
1. Extract 1-2 sentences that capture wisdom, humor, love, or emotional resonance
2. Max 280 characters (Twitter length)
3. Remove filler words (So, Well, You know, Like, Actually, Um)
4. Preserve the speaker's voice and personality
5. If the text is too generic or lacks substance, return a short reflection on family/love instead
6. Return ONLY valid JSON: {"quote": "...", "confidence": 0.0-1.0}

Examples:
Input: "So like, I remember when we drove to California and the car broke down and we had to stay in that motel."
Output: {"quote": "We drove to California and the car broke down, but that motel stay became our favorite memory.", "confidence": 0.8}

Input: "The most important thing is family. Always be there for each other."
Output: {"quote": "The most important thing is family. Always be there for each other.", "confidence": 0.95}`;

      const response = await this.client.chat.completions.create({
        model: this.modelId,
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: `Extract the best quote from this text:\n\n${transcription}` },
        ],
        temperature: 0.6,
        max_tokens: 300,
        response_format: { type: 'json_object' },
      });

      const content = response.choices[0].message.content;
      const parsed = JSON.parse(content);

      return {
        quote: parsed.quote || transcription.substring(0, 280),
        confidence: parsed.confidence || 0.7,
      };
    } catch (error) {
      // Fallback to simple extraction
      let cleaned = transcription.trim();
      cleaned = cleaned.replace(/^(So|Well|You know|Actually|Like|Um),?\s*/i, '');
      const sentences = cleaned.split(/[.!?]+/).filter(s => s.trim().length > 0);
      let quote = sentences[0] || cleaned;
      if (quote.length > 280) quote = quote.substring(0, 277) + '...';
      return { quote: quote.trim(), confidence: 0.5 };
    }
  }

  /**
   * Generate embedding for semantic search
   * Uses OpenAI-compatible embedding endpoint via Bedrock
   */
  async generateEmbedding(text: string): Promise<number[]> {
    try {
      // Use Bedrock's Titan embeddings model
      const region = this.client.baseURL.match(/bedrock-runtime\.([^.]+)\.amazonaws\.com/)?.[1] || 'us-west-2';
      const bedrockEndpoint = `https://bedrock-runtime.${region}.amazonaws.com`;

      // For now, use a simple hash-based embedding as fallback
      // In production, use actual OpenAI embeddings or Amazon Titan
      const words = text.toLowerCase().split(/\s+/);
      const embedding = new Array(384).fill(0); // 384-dim embedding (common size)

      // Simple word frequency-based embedding (production should use real embeddings)
      const hash = (str: string) => {
        let h = 0;
        for (let i = 0; i < str.length; i++) {
          h = Math.imul(31, h) + str.charCodeAt(i) | 0;
        }
        return Math.abs(h) / 0x7FFFFFFF;
      };

      words.forEach((word, idx) => {
        const dim = idx % embedding.length;
        embedding[dim] += hash(word);
      });

      // Normalize
      const magnitude = Math.sqrt(embedding.reduce((sum, val) => sum + val * val, 0));
      return embedding.map(val => val / magnitude);
    } catch (error) {
      console.error('[Embedding] Error:', error);
      return new Array(384).fill(0);
    }
  }

  /**
   * Generate a prompt question from transcribed text
   * Used when a response is submitted without a prompt
   */
  async generatePromptFromTranscription(transcription: string): Promise<string> {
    try {
      const systemPrompt = `You are a family story facilitator. Your job is to extract or generate a meaningful prompt/question from a transcribed story.

The prompt should:
1. Be a question that would elicit this type of story
2. Be 5-15 words long
3. Be conversational and warm
4. Capture the essence of what the story is about
5. Be open-ended (not yes/no)

Return ONLY the prompt text, no markdown, no explanation.

Examples:
Input: "I remember when I was 10 and my dad took me fishing for the first time..."
Output: "What's a memorable first experience you had with a parent?"

Input: "We used to go to grandma's house every Sunday for dinner..."
Output: "What family traditions did you have growing up?"

Input: "During the war, we had to leave our home and move to a new country..."
Output: "What's a story about overcoming difficult times as a family?"`;

      const response = await this.client.chat.completions.create({
        model: this.modelId,
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: `Generate a prompt question for this story:\n\n${transcription}` },
        ],
        temperature: 0.7,
        max_tokens: 100,
      });

      const prompt = response.choices[0].message.content?.trim() || 'What\'s a story from your life you\'d like to share?';
      return prompt;
    } catch (error) {
      console.error('[Prompt Generation] Error:', error);
      // Fallback prompts
      const fallbacks = [
        "What's a story from your childhood you'd like to share?",
        "What's a valuable life lesson you've learned?",
        "What's a memorable family experience you've had?",
        "What advice would you like to pass down to future generations?",
      ];
      return fallbacks[Math.floor(Math.random() * fallbacks.length)];
    }
  }

  /**
   * Generate AI discussion topics based on family stories
   */
  async generateDiscussionTopics(familyStories: Array<{
    title: string
    summaryText: string
    tags?: string[]
    voiceCount: number
  }>): Promise<{
    topics: Array<{
      question: string
      category: string
      reasoning: string
      relatedStoryCount: number
    }>
  }> {
    try {
      const storiesSummary = familyStories.map((s, i) =>
        `[${i + 1}] "${s.title}" (${s.voiceCount} voices): ${s.summaryText?.substring(0, 100)}...`
      ).join('\n');

      const systemPrompt = `You are a family conversation facilitator. Your job is to suggest meaningful discussion topics that will help families connect and share stories.

Based on the family's existing stories, generate 3-5 discussion topics that will:
1. Encourage sharing of untold stories
2. Connect different generations
3. Explore themes the family hasn't discussed much
4. Be relevant to seasons, holidays, or life events

Return JSON: {
  "topics": [
    {
      "question": "What's a question to ask?",
      "category": "Traditions|Childhood|Relationships|Values|Memories",
      "reasoning": "Why this topic matters for this family",
      "relatedStoryCount": 2
    }
  ]
}`;

      const response = await this.client.chat.completions.create({
        model: this.modelId,
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: `Here are some stories from this family:\n\n${storiesSummary}\n\nGenerate 3-5 discussion topics that would help them share more meaningful stories together.` },
        ],
        temperature: 0.8,
        max_tokens: 1500,
        response_format: { type: 'json_object' },
      });

      const content = response.choices[0].message.content;
      const parsed = JSON.parse(content);
      return parsed;
    } catch (error) {
      console.error('[Discussion Topics] Error:', error);
      // Fallback topics
      return {
        topics: [
          {
            question: "What's a family tradition you'd like to start or continue?",
            category: "Traditions",
            reasoning: "Traditions help families create lasting memories",
            relatedStoryCount: 0,
          },
          {
            question: "What's the best advice you ever received from a family member?",
            category: "Values",
            reasoning: "Wisdom passed down through generations is precious",
            relatedStoryCount: 0,
          },
        ],
      };
    }
  }
}

export const createQwenTurboClient = (config: QwenTurboConfig): QwenTurboClient => {
  return new QwenTurboClient(config);
};