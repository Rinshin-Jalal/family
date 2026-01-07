// src/ai/wisdom-summarizer.ts

import OpenAI from 'openai';
import { AIServiceError } from './types';

// ============================================================================
// AI WISDOM SUMMARIZER
// Generates "What family learned" summaries from multiple stories
// ============================================================================

export interface WisdomSummaryInput {
  stories: Array<{
    id: string
    title: string
    summaryText: string
    speakerName: string
    speakerRole: string
    year?: string
  }>
  question: string
}

export interface WisdomSummaryResult {
  summary: string
  whatHappened: string[]
  whatLearned: string[]
  guidance: string[]
  generation?: string
}

// Predefined templates for different question types
const QUESTION_TEMPLATES: Record<string, string> = {
  money: 'How did your family handle money problems?',
  divorce: 'How did your family handle divorce or separation?',
  job: 'How did you handle job loss or career changes?',
  illness: 'How did your family deal with illness or health challenges?',
  immigration: 'What was it like immigrating to a new country?',
  parenting: 'What advice do you have about raising children?',
  marriage: "What's the secret to a long marriage?",
  grief: 'How did your family cope with loss?',
  default: 'What life lessons have you learned?',
}

export class WisdomSummarizerClient {
  private client: OpenAI;
  private modelId: string;

  constructor(config: { openaiApiKey: string; modelId?: string; bedrockRegion?: string }) {
    if (!config.openaiApiKey || config.openaiApiKey.includes('placeholder')) {
      throw new AIServiceError(
        'OPENAI_API_KEY is required for wisdom summarization',
        'wisdom-summarizer'
      );
    }

    this.modelId = config.modelId || 'openai.gpt-4o';

    const bedrockRegion = config.bedrockRegion || 'us-west-2';
    const bedrockEndpoint = `https://bedrock-runtime.${bedrockRegion}.amazonaws.com/openai/v1`;

    this.client = new OpenAI({
      apiKey: config.openaiApiKey,
      baseURL: bedrockEndpoint,
    });
  }

  async generateSummary(input: WisdomSummaryInput): Promise<WisdomSummaryResult> {
    try {
      const storiesText = input.stories
        .map((s, idx) => {
          return `[${idx + 1}] ${s.speakerName} (${s.speakerRole})${s.year ? ` - ${s.year}` : ''}: "${s.summaryText}"`
        })
        .join('\n\n');

      const systemPrompt = `You are a family wisdom synthesizer. Your job is to analyze multiple family stories and extract the collective wisdom - what the family learned, how they handled challenges, and guidance for future generations.

Rules:
1. Synthesize the stories into a coherent summary (2-3 paragraphs)
2. Extract 3-5 "What happened" points - the situations faced
3. Extract 3-5 "What learned" points - the lessons extracted
4. Extract 2-4 "Guidance" points - actionable advice
5. Identify the generation if possible (grandma, grandpa, etc.)
6. Return ONLY valid JSON, no markdown

Response format:
{
  "summary": "2-3 paragraph synthesis of all stories",
  "whatHappened": ["situation 1", "situation 2", ...],
  "whatLearned": ["lesson 1", "lesson 2", ...],
  "guidance": ["advice 1", "advice 2", ...],
  "generation": "e.g., 'grandparents' or 'parents'"
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
            content: `The family is asking: "${input.question}"

Here are the stories from family members:\n\n${storiesText}\n\nSynthesize this wisdom into a meaningful summary.`,
          },
        ],
        temperature: 0.5,
        max_tokens: 2000,
        response_format: { type: 'json_object' },
      });

      return this.parseSummaryResponse(response);
    } catch (error) {
      throw new AIServiceError(
        'Failed to generate wisdom summary',
        'wisdom-summarizer',
        error
      );
    }
  }

  async generateStorySummary(story: {
    id: string
    title: string
    summaryText: string
    responses: Array<{
      transcription_text: string
      profiles: { full_name: string; role: string }
    }>
  }): Promise<string> {
    try {
      const combinedText = story.responses
        .map(r => `${r.profiles.full_name}: ${r.transcription_text}`)
        .join('\n\n');

      const response = await this.client.chat.completions.create({
        model: this.modelId,
        messages: [
          {
            role: 'system',
            content: `You are a family story summarizer. Create a concise, heartwarming summary (2-3 sentences) that captures the essence of this family story. Include the key message or lesson if present. Return ONLY the summary text, no markdown.`,
          },
          {
            role: 'user',
            content: `Story: "${story.title}"\n\n${combinedText}`,
          },
        ],
        temperature: 0.5,
        max_tokens: 300,
      });

      return response.choices[0].message.content || story.summaryText;
    } catch (error) {
      return story.summaryText; // Fallback to existing summary
    }
  }

  async generateKidFriendlySummary(
    story: {
      title: string
      responses: Array<{
        transcription_text: string
        profiles: { full_name: string; role: string }
      }>
    },
    kidAge: number = 8
  ): Promise<string> {
    try {
      const combinedText = story.responses
        .map(r => `${r.profiles.full_name}: ${r.transcription_text}`)
        .join('\n\n');

      const ageAppropriate = kidAge < 6 ? 'very simple' : kidAge < 10 ? 'simple' : 'approachable';

      const response = await this.client.chat.completions.create({
        model: this.modelId,
        messages: [
          {
            role: 'system',
            content: `You are telling a family story to a ${kidAge}-year-old child. Use ${ageAppropriate} language, focus on the positive message, and make it feel like a warm conversation with grandma or grandpa. Keep it under 150 words. Return ONLY the story, no markdown.`,
          },
          {
            role: 'user',
            content: `Story: "${story.title}"\n\n${combinedText}`,
          },
        ],
        temperature: 0.7,
        max_tokens: 500,
      });

      return response.choices[0].message.content || 'This is a story about family love.';
    } catch (error) {
      return 'This is a special story from your family!';
    }
  }

  private parseSummaryResponse(response: any): WisdomSummaryResult {
    try {
      const content = response.choices[0].message.content;
      const parsed = JSON.parse(content);

      return {
        summary: parsed.summary || '',
        whatHappened: parsed.whatHappened || [],
        whatLearned: parsed.whatLearned || [],
        guidance: parsed.guidance || [],
        generation: parsed.generation,
      };
    } catch (error) {
      throw new AIServiceError(
        'Failed to parse wisdom summary response as JSON',
        'wisdom-summarizer',
        error
      );
    }
  }
}

export const createWisdomSummarizerClient = (config: {
  openaiApiKey: string
  modelId?: string
  bedrockRegion?: string
}): WisdomSummarizerClient => {
  return new WisdomSummarizerClient(config);
};
