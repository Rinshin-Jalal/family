// src/ai/wisdom-tagger.ts

import OpenAI from 'openai';
import { AIServiceError } from './types';

// ============================================================================
// WISDOM TAGGING SERVICE
// Extracts emotions, situations, lessons, and guidance from story transcriptions
// ============================================================================

export interface WisdomTaggingInput {
  storyId: string;
  transcriptions: string[];
  speakerRoles: string[];
  speakerNames: string[];
}

export interface WisdomTaggingResult {
  storyId: string;
  emotionTags: string[];
  situationTags: string[];
  lessonTags: string[];
  guidanceTags: string[];
  questionKeywords: string[];
  confidence: number;
}

// Predefined tag vocabularies for consistency
export const EMOTION_TAGS = [
  'anxiety', 'fear', 'joy', 'grief', 'hope', 'love', 'anger',
  'frustration', 'excitement', 'sadness', 'pride', 'gratitude',
  'loneliness', 'determination', 'humor', 'nostalgia', 'peace',
  'overwhelm', 'relief', 'triumph', 'disappointment', 'wonder'
];

export const SITUATION_TAGS = [
  'divorce', 'job-loss', 'money-problems', 'first-job', 'immigration',
  'moving-house', 'pregnancy', 'parenthood', 'marriage', 'death',
  'illness', 'accident', 'war', 'discrimination', 'poverty',
  'success', 'travel', 'education', 'career-change', 'retirement',
  'family-gathering', 'holiday', 'childhood', 'teenage-years',
  'military-service', 'entrepreneurship', 'spiritual-awakening'
];

export const LESSON_TAGS = [
  'survival', 'hope', 'resilience', 'family-togetherness', 'forgiveness',
  'persistence', 'adaptability', 'gratitude', 'hard-work', 'education',
  'love-conquers-all', 'communication', 'compromise', 'patience',
  'taking-risks', 'learning-from-mistakes', 'humility', 'generosity',
  'independence', 'community-support', 'faith', ' perseverance'
];

export const GUIDANCE_TAGS = [
  'what-to-do', 'what-not-to-do', 'advice', 'warning', 'encouragement',
  'caution', 'recommendation', 'life-lesson', 'wisdom', 'values',
  'priorities', 'relationships', 'career', 'money', 'health', 'family'
];

export class WisdomTaggerClient {
  private client: OpenAI;
  private modelId: string;

  constructor(config: { openaiApiKey: string; modelId?: string; bedrockRegion?: string }) {
    if (!config.openaiApiKey || config.openaiApiKey.includes('placeholder')) {
      throw new AIServiceError(
        'AWS_BEARER_TOKEN_BEDROCK is required for wisdom tagging',
        'wisdom-tagger'
      );
    }

    this.modelId = config.modelId || 'openai.gpt-oss-20b-1:0';

    // Use direct OpenAI or Bedrock endpoint
    const bedrockRegion = config.bedrockRegion || 'us-west-2';
    const bedrockEndpoint = `https://bedrock-runtime.${bedrockRegion}.amazonaws.com/openai/v1`;

    this.client = new OpenAI({
      apiKey: config.openaiApiKey,
      baseURL: bedrockEndpoint,
    });
  }

  async tagStory(input: WisdomTaggingInput): Promise<WisdomTaggingResult> {
    try {
      const combinedText = input.transcriptions.join('\n\n');
      const speakers = input.speakerNames.map((name, idx) => ({
        name,
        role: input.speakerRoles[idx],
      }));

      const systemPrompt = `You are a wisdom extraction specialist for a family storytelling app. Your job is to analyze family stories and extract searchable tags that help family members find relevant wisdom.

Rules:
1. Extract 3-6 emotion tags (from the allowed list when possible)
2. Extract 2-5 situation tags (from the allowed list when possible)
3. Extract 2-4 life lesson tags (from the allowed list when possible)
4. Extract 1-3 guidance tags (from the allowed list when possible)
5. Generate 3-5 question keywords that someone might ask to find this story
6. Assign a confidence score (0.5-1.0) based on how clear the wisdom is in the story
7. Return ONLY valid JSON, no markdown

EMOTION TAGS (prefer from this list):
${EMOTION_TAGS.join(', ')}

SITUATION TAGS (prefer from this list):
${SITUATION_TAGS.join(', ')}

LESSON TAGS (prefer from this list):
${LESSON_TAGS.join(', ')}

GUIDANCE TAGS (prefer from this list):
${GUIDANCE_TAGS.join(', ')}

Example output:
{
  "emotionTags": ["hope", "resilience", "gratitude"],
  "situationTags": ["job-loss", "immigration"],
  "lessonTags": ["persistence", "family-togetherness"],
  "guidanceTags": ["what-to-do", "advice"],
  "questionKeywords": [
    "how did family handle job loss",
    "immigration stories advice",
    "staying positive during hard times"
  ],
  "confidence": 0.85
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
            content: `Analyze this family story and extract wisdom tags:\n\n${combinedText}\n\nSpeakers: ${speakers.map(s => `${s.name} (${s.role})`).join(', ')}`,
          },
        ],
        temperature: 0.3,
        max_tokens: 1000,
        response_format: { type: 'json_object' },
      });

      return this.parseTaggingResponse(input.storyId, response);
    } catch (error) {
      throw new AIServiceError(
        'Failed to tag story with wisdom categories',
        'wisdom-tagger',
        error
      );
    }
  }

  private parseTaggingResponse(storyId: string, response: any): WisdomTaggingResult {
    try {
      const content = response.choices[0].message.content;
      const parsed = JSON.parse(content);

      return {
        storyId,
        emotionTags: parsed.emotionTags || [],
        situationTags: parsed.situationTags || [],
        lessonTags: parsed.lessonTags || [],
        guidanceTags: parsed.guidanceTags || [],
        questionKeywords: parsed.questionKeywords || [],
        confidence: parsed.confidence || 0.5,
      };
    } catch (error) {
      throw new AIServiceError(
        'Failed to parse wisdom tagging response as JSON',
        'wisdom-tagger',
        error
      );
    }
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

export const createWisdomTaggerClient = (config: {
  openaiApiKey: string;
  modelId?: string;
  bedrockRegion?: string;
}): WisdomTaggerClient => {
  return new WisdomTaggerClient(config);
};
