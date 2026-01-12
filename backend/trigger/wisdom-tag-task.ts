// ============================================================================
// TRIGGER.DEV TASKS - Wisdom Tagging (DEPRECATED)
// ============================================================================
//
// ⚠️  DEPRECATED: Wisdom tagging is now done at the RESPONSE level via response-tag-task.ts
//    This file is kept for backward compatibility with existing stories.
//
// For new stories, wisdom tags are generated per-response during transcription.
// For existing stories, you can still trigger this task manually if needed.
// ============================================================================

import { task } from "@trigger.dev/sdk";
import { createClient } from "@supabase/supabase-js";
import OpenAI from "openai";

// ============================================================================
// TYPES
// ============================================================================

interface TagStoryWisdomPayload {
  storyId: string;
  triggeredBy: "story_completion" | "manual_request";
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
// TASK DEFINITION
// ============================================================================

/**
 * Tag Story with Wisdom Categories
 *
 * Analyzes a story and tags it with:
 * - Emotion tags (joy, sadness, nostalgia, etc.)
 * - Situation tags (childhood, parenting, career, etc.)
 * - Lesson tags (what was learned)
 * - Guidance tags (advice for future)
 *
 * This enables semantic search and value extraction.
 */
export const tagStoryWisdomTask = task({
  id: "tag-story-wisdom",
  description: "Tag a story with wisdom categories (emotions, situations, lessons, guidance)",
  retry: {
    maxAttempts: 3,
    factor: 2,
    minTimeoutInMs: 1000,
    maxTimeoutInMs: 10000,
  },
  run: async (payload: TagStoryWisdomPayload, { ctx }) => {
    console.log(`[Wisdom] Starting tag generation for story ${payload.storyId}`);

    const supabase = createSupabaseClient();
    const bedrock = createBedrockClient();

    // Step 1: Fetch story with responses
    const { data: story, error: fetchError } = await supabase
      .from("stories")
      .select(
        `
        id,
        title,
        responses (
          id,
          transcription_text,
          profiles (
            role,
            full_name
          )
        )
      `
      )
      .eq("id", payload.storyId)
      .single();

    if (fetchError || !story) {
      throw new Error(`Failed to fetch story: ${fetchError?.message || "Not found"}`);
    }

    const responses = story.responses || [];
    const transcriptions = responses
      .filter((r: any) => r.transcription_text)
      .map((r: any) => r.transcription_text);

    if (transcriptions.length === 0) {
      console.log(`[Wisdom] No transcriptions found, skipping`);
      return {
        success: true,
        skipped: true,
        reason: "no_transcriptions",
        storyId: payload.storyId,
      };
    }

    console.log(`[Wisdom] Processing ${transcriptions.length} transcriptions...`);

    // Step 2: Extract speaker info
    const speakerRoles = responses.map((r: any) => r.profiles?.role || "member");
    const speakerNames = responses.map((r: any) => r.profiles?.full_name || "Family Member");

    // Step 3: Call AI tagging service (AWS Bedrock)
    console.log(`[Wisdom] Tagging story with AI...`);

    try {
      // Combine all transcriptions for context
      const fullStory = transcriptions.join("\n\n");

      const completion = await bedrock.chat.completions.create({
        model: "qwen.qwen3-next-80b-a3b",
        messages: [
          {
            role: "system",
            content: `You are an expert at analyzing family stories and extracting meaningful wisdom categories.

Your task: Analyze the family story and extract tags in these categories:

1. **emotion_tags** (3-7 tags): How the story feels emotionally
   Examples: nostalgia, joy, sadness, pride, love, hope, gratitude, warmth, humor

2. **situation_tags** (3-7 tags): What the story is about
   Examples: childhood_memory, family_tradition, parenting, celebration, hardship, triumph, learning_moment, bonding

3. **lesson_tags** (2-5 tags): What was learned or gained
   Examples: importance_of_family, value_of_storytelling, resilience, love_endures, memories_matter, gratitude

4. **guidance_tags** (2-5 tags): Advice for future generations
   Examples: cherish_time_together, listen_to_elders, document_memories, share_stories, celebrate_small_moments

5. **question_keywords** (2-5 tags): Questions this story could answer
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

Confidence (0.0-1.0) should reflect how confident you are that these tags accurately represent the story.`,
          },
          {
            role: "user",
            content: `Analyze this family story and extract wisdom tags:\n\nStory: "${fullStory}"\n\nSpeakers: ${speakerNames.join(", ")}\n\nRespond with JSON only.`,
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
        `[Wisdom] Generated ${tags.emotion_tags.length} emotions, ${tags.situation_tags.length} situations, ${tags.lesson_tags.length} lessons, ${tags.guidance_tags.length} guidance`
      );

      // Step 4: Only save if there are actual tags
      const totalTags =
        (tags.emotion_tags?.length || 0) +
        (tags.situation_tags?.length || 0) +
        (tags.lesson_tags?.length || 0) +
        (tags.guidance_tags?.length || 0) +
        (tags.question_keywords?.length || 0);

      if (totalTags === 0) {
        console.log(`[Wisdom] No tags generated, skipping save`);
        return {
          success: true,
          skipped: true,
          reason: "no_tags_generated",
          storyId: payload.storyId,
        };
      }

      // Step 5: story_tags table removed - tags no longer saved
      console.log(`[Wisdom] ✅ Tags generated for story ${payload.storyId} (not saved - story_tags table removed)`);

      return {
        success: true,
        storyId: payload.storyId,
        emotionCount: tags.emotion_tags?.length || 0,
        situationCount: tags.situation_tags?.length || 0,
        lessonCount: tags.lesson_tags?.length || 0,
        guidanceCount: tags.guidance_tags?.length || 0,
        totalTags,
        confidence: tags.confidence,
        tags: tags, // Return tags but don't save them
      };
    } catch (error) {
      console.error(`[Wisdom] ❌ AI tagging failed:`, error);
      return {
        success: true,
        skipped: true,
        reason: "ai_failed",
        error: error instanceof Error ? error.message : String(error),
        storyId: payload.storyId,
      };
    }
  },
});
