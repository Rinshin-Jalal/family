// ============================================================================
// TRIGGER.DEV TASKS - Response Wisdom Tagging
// ============================================================================
//
// Tags individual responses with wisdom categories (emotions, situations, lessons, guidance).
// This shifts wisdom tagging from story-level to response-level as requested.
// ============================================================================

import { task } from "@trigger.dev/sdk";
import { createClient } from "@supabase/supabase-js";
import OpenAI from "openai";

// ============================================================================
// TYPES
// ============================================================================

interface TagResponseWisdomPayload {
  responseId: string;
  triggeredBy: "response.transcribed" | "story.completed" | "manual_request";
}

// ============================================================================
// CLIENTS
// ============================================================================

// Environment variables (will be loaded by trigger.dev)
const supabaseUrl = process.env.SUPABASE_URL!;
const supabaseKey = process.env.SUPABASE_KEY!;
const awsBedrockToken = process.env.AWS_BEARER_TOKEN_BEDROCK!;
const awsRegion = process.env.AWS_REGION || "us-east-1";

function createSupabaseClient() {
  return createClient(supabaseUrl, supabaseKey);
}

function createBedrockClient() {
  return new OpenAI({
    baseURL: `https://bedrock-runtime.${awsRegion}.amazonaws.com/openai/v1`,
    apiKey: awsBedrockToken,
  });
}

// ============================================================================
// PREDEFINED TAG VOCABULARIES (from wisdom-tagger.ts)
// ============================================================================

const EMOTION_TAGS = [
  'anxiety', 'fear', 'joy', 'grief', 'hope', 'love', 'anger',
  'frustration', 'excitement', 'sadness', 'pride', 'gratitude',
  'loneliness', 'determination', 'humor', 'nostalgia', 'peace',
  'overwhelm', 'relief', 'triumph', 'disappointment', 'wonder'
];

const SITUATION_TAGS = [
  'divorce', 'job-loss', 'money-problems', 'first-job', 'immigration',
  'moving-house', 'pregnancy', 'parenthood', 'marriage', 'death',
  'illness', 'accident', 'war', 'discrimination', 'poverty',
  'success', 'travel', 'education', 'career-change', 'retirement',
  'family-gathering', 'holiday', 'childhood', 'teenage-years',
  'military-service', 'entrepreneurship', 'spiritual-awakening'
];

const LESSON_TAGS = [
  'survival', 'hope', 'resilience', 'family-togetherness', 'forgiveness',
  'persistence', 'adaptability', 'gratitude', 'hard-work', 'education',
  'love-conquers-all', 'communication', 'compromise', 'patience',
  'taking-risks', 'learning-from-mistakes', 'humility', 'generosity',
  'independence', 'community-support', 'faith', 'perseverance'
];

const GUIDANCE_TAGS = [
  'what-to-do', 'what-not-to-do', 'advice', 'warning', 'encouragement',
  'caution', 'recommendation', 'life-lesson', 'wisdom', 'values',
  'priorities', 'relationships', 'career', 'money', 'health', 'family'
];

// ============================================================================
// TASK DEFINITION
// ============================================================================

/**
 * Tag Response with Wisdom Categories
 *
 * Analyzes an individual response and tags it with:
 * - Emotion tags (joy, sadness, nostalgia, etc.)
 * - Situation tags (childhood, parenting, career, etc.)
 * - Lesson tags (what was learned)
 * - Guidance tags (advice for future)
 * - Question keywords (for searchability)
 *
 * This enables semantic search and value extraction at the response level.
 */
export const tagResponseWisdomTask = task({
  id: "tag-response-wisdom",
  description: "Tag a response with wisdom categories (emotions, situations, lessons, guidance)",
  retry: {
    maxAttempts: 3,
    factor: 2,
    minTimeoutInMs: 1000,
    maxTimeoutInMs: 10000,
  },
  run: async (payload: TagResponseWisdomPayload, { ctx }) => {
    console.log(`[ResponseWisdom] Starting tag generation for response ${payload.responseId}`);

    const supabase = createSupabaseClient();
    const bedrock = createBedrockClient();

    // Step 1: Fetch response with profile
    const { data: response, error: fetchError } = await supabase
      .from("responses")
      .select(`
        id,
        transcription_text,
        story_id,
        user_id,
        profiles (
          id,
          full_name,
          role,
          family_id
        )
      `)
      .eq("id", payload.responseId)
      .single();

    if (fetchError || !response) {
      throw new Error(`Failed to fetch response: ${fetchError?.message || "Not found"}`);
    }

    const transcriptionText = response.transcription_text;
    if (!transcriptionText || transcriptionText.length < 50) {
      console.log(`[ResponseWisdom] Text too short (${transcriptionText?.length || 0} chars), skipping`);
      return {
        success: true,
        skipped: true,
        reason: "text_too_short",
        responseId: payload.responseId,
      };
    }

    const speakerName = response.profiles?.full_name || "Family Member";
    const speakerRole = response.profiles?.role || "member";

    console.log(`[ResponseWisdom] Processing response from ${speakerName} (${speakerRole})`);

    // Step 2: Call AI tagging service (AWS Bedrock)
    try {
      const completion = await bedrock.chat.completions.create({
        model: "qwen.qwen3-next-80b-a3b",
        messages: [
          {
            role: "system",
            content: `You are an expert at analyzing family stories and extracting meaningful wisdom categories.

Your task: Analyze the response and extract tags in these categories:

1. **emotion_tags** (3-6 tags): How the response feels emotionally
   Examples: nostalgia, joy, sadness, pride, love, hope, gratitude, warmth, humor

2. **situation_tags** (3-6 tags): What the response is about
   Examples: childhood_memory, family_tradition, parenting, celebration, hardship, triumph, learning_moment, bonding

3. **lesson_tags** (2-4 tags): What was learned or gained
   Examples: importance_of_family, value_of_storytelling, resilience, love_endures, memories_matter, gratitude

4. **guidance_tags** (2-4 tags): Advice or guidance in the response
   Examples: cherish_time_together, listen_to_elders, document_memories, share_stories, celebrate_small_moments

5. **question_keywords** (3-5 tags): Questions this response could answer
   Examples: childhood, family_traditions, parenting_wisdom, life_lessons, memories

IMPORTANT:
- Tags should be lowercase_with_underscores
- Be specific but not too narrow
- Only add tags that are truly relevant
- Respond with valid JSON in this exact format:
{
  "emotion_tags": ["nostalgia", "joy", "warmth"],
  "situation_tags": ["childhood_memory", "family_tradition"],
  "lesson_tags": ["importance_of_family", "memories_matter"],
  "guidance_tags": ["cherish_time_together"],
  "question_keywords": ["childhood", "traditions"],
  "confidence": 0.85
}

Confidence (0.0-1.0) should reflect how confident you are that these tags accurately represent the response.`,
          },
          {
            role: "user",
            content: `Analyze this family story response and extract wisdom tags:

Response: "${transcriptionText}"

Speaker: ${speakerName} (${speakerRole})

Respond with JSON only.`,
          },
        ],
        max_tokens: 500,
        temperature: 0.6,
        response_format: { type: "json_object" },
      });

      const message = completion.choices[0]?.message;
      if (!message?.content) {
        throw new Error("No response from Bedrock");
      }

      const tags = JSON.parse(message.content);

      console.log(
        `[ResponseWisdom] Generated ${tags.emotion_tags?.length || 0} emotions, ${tags.situation_tags?.length || 0} situations, ${tags.lesson_tags?.length || 0} lessons, ${tags.guidance_tags?.length || 0} guidance`
      );

      // Step 3: Calculate total tags
      const totalTags =
        (tags.emotion_tags?.length || 0) +
        (tags.situation_tags?.length || 0) +
        (tags.lesson_tags?.length || 0) +
        (tags.guidance_tags?.length || 0) +
        (tags.question_keywords?.length || 0);

      if (totalTags === 0) {
        console.log(`[ResponseWisdom] No tags generated, skipping save`);
        return {
          success: true,
          skipped: true,
          reason: "no_tags_generated",
          responseId: payload.responseId,
        };
      }

      // Step 4: Save tags to response_tags table
      const { data: savedTags, error: upsertError } = await supabase
        .from("response_tags")
        .upsert(
          {
            response_id: payload.responseId,
            emotion_tags: tags.emotion_tags || [],
            situation_tags: tags.situation_tags || [],
            lesson_tags: tags.lesson_tags || [],
            guidance_tags: tags.guidance_tags || [],
            question_keywords: tags.question_keywords || [],
            confidence: tags.confidence,
            source: "ai",
            updated_at: new Date().toISOString(),
          },
          {
            onConflict: "response_id",
            ignoreDuplicates: false,
          }
        )
        .select()
        .single();

      if (upsertError) {
        throw new Error(`Failed to save tags: ${upsertError.message}`);
      }

      console.log(`[ResponseWisdom] ✅ Saved tags for response ${payload.responseId}`);

      return {
        success: true,
        responseId: payload.responseId,
        storyId: response.story_id,
        emotionCount: tags.emotion_tags?.length || 0,
        situationCount: tags.situation_tags?.length || 0,
        lessonCount: tags.lesson_tags?.length || 0,
        guidanceCount: tags.guidance_tags?.length || 0,
        totalTags,
        confidence: tags.confidence,
      };
    } catch (error) {
      console.error(`[ResponseWisdom] ❌ AI tagging failed:`, error);
      return {
        success: true,
        skipped: true,
        reason: "ai_failed",
        error: error instanceof Error ? error.message : String(error),
        responseId: payload.responseId,
      };
    }
  },
});
