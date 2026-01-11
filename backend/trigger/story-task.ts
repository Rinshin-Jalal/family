import { task } from "@trigger.dev/sdk";
import { createClient } from "@supabase/supabase-js";
import OpenAI from "openai";

// Environment variables (will be loaded by trigger.dev)
const supabaseUrl = process.env.SUPABASE_URL!;
const supabaseKey = process.env.SUPABASE_KEY!;
const awsBedrockToken = process.env.AWS_BEARER_TOKEN_BEDROCK!;
const awsRegion = process.env.AWS_REGION || "us-east-1";

// Create a simple Supabase client for background tasks
function createSupabaseClient() {
  return createClient(supabaseUrl, supabaseKey);
}

// Create OpenAI client configured for AWS Bedrock
function createBedrockClient() {
  return new OpenAI({
    baseURL: `https://bedrock-runtime.${awsRegion}.amazonaws.com/openai/v1`,
    apiKey: awsBedrockToken,
  });
}

/**
 * Auto-create a story for a response
 * This runs after prompt generation
 */
export const createStoryTask = task({
  id: "create-story-from-response",
  description: "Auto-create a story when a response is submitted without one",
  retry: {
    maxAttempts: 3,
    factor: 2,
    minTimeoutInMs: 1000,
    maxTimeoutInMs: 10000,
  },
  run: async (payload: { responseId: string; promptText: string; familyId: string; transcriptionText?: string }, { ctx }) => {
    const supabase = createSupabaseClient();
    const bedrock = createBedrockClient();

    // Generate title and summary for the story using AI
    let storyTitle = "Untitled Story";
    let storySummary = null;

    if (payload.transcriptionText) {
      try {
        const completion = await bedrock.chat.completions.create({
          model: "qwen.qwen3-next-80b-a3b",
          messages: [
            {
              role: "system",
              content: `You are a creative story analyzer for family memories. Generate:
1. A short, engaging title (3-6 words)
2. A brief summary (2-3 sentences max) that captures the essence and emotional core of the story

You must respond with valid JSON in this exact format:
{"title": "Your Story Title", "summary": "Your 2-3 sentence summary here."}`,
            },
            {
              role: "user",
              content: `Generate a title and summary for this story: "${payload.transcriptionText}"

Respond with JSON only.`,
            },
          ],
          max_tokens: 200,
          temperature: 0.7,
          response_format: { type: "json_object" },
        });

        const message = completion.choices[0]?.message;
        if (message?.content) {
          const jsonResponse = JSON.parse(message.content);
          const generatedTitle = jsonResponse.title?.trim();
          const generatedSummary = jsonResponse.summary?.trim();

          if (generatedTitle && generatedTitle.length > 3) {
            storyTitle = generatedTitle;
            console.log(`✓ AI-generated title: ${storyTitle}`);
          }

          if (generatedSummary && generatedSummary.length > 10) {
            storySummary = generatedSummary;
            console.log(`✓ AI-generated summary: ${storySummary}`);
          }
        }
      } catch (error) {
        console.warn(`Title/summary generation failed, using defaults:`, error);
      }
    }

    // Create a new story with embedded prompt fields
    const { data: newStory, error: storyError } = await supabase
      .from("stories")
      .insert({
        family_id: payload.familyId,
        title: storyTitle,
        summary_text: storySummary,
        prompt_text: payload.promptText,
        prompt_category: categorizePrompt(payload.promptText),
        prompt_is_custom: true,
        voice_count: 1,
        is_completed: false,
      })
      .select()
      .single();

    if (storyError || !newStory) {
      throw new Error(`Failed to create story: ${JSON.stringify(storyError)}`);
    }

    console.log(`✓ Story created: ${newStory.id}`);

    // Update the response with the new story_id
    const { error: updateError } = await supabase
      .from("responses")
      .update({ story_id: newStory.id })
      .eq("id", payload.responseId);

    if (updateError) {
      throw new Error(`Failed to update response: ${JSON.stringify(updateError)}`);
    }

    return {
      success: true,
      storyId: newStory.id,
      responseId: payload.responseId,
    };
  },
});

// Helper function to categorize prompts
function categorizePrompt(promptText: string): string {
  const lower = promptText.toLowerCase();

  if (lower.includes('childhood') || lower.includes('when you were') || lower.includes('growing up')) {
    return 'childhood';
  }
  if (lower.includes('holiday') || lower.includes('christmas') || lower.includes('thanksgiving')) {
    return 'holidays';
  }
  if (lower.includes('funny') || lower.includes('laugh') || lower.includes('embarrassing')) {
    return 'funny';
  }
  if (lower.includes('love') || lower.includes('relationship') || lower.includes('met')) {
    return 'love';
  }
  if (lower.includes('work') || lower.includes('job') || lower.includes('career')) {
    return 'career';
  }

  return 'life'; // Default category
}
