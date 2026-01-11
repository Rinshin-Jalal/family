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
 * Generate a prompt from transcribed text and link to response
 * This runs in the background after a response is submitted
 */
export const generatePromptTask = task({
  id: "generate-prompt-from-transcription",
  description: "AI-generate a prompt question from transcribed story text",
  retry: {
    maxAttempts: 3,
    factor: 2,
    minTimeoutInMs: 1000,
    maxTimeoutInMs: 10000,
  },
  run: async (payload: { responseId: string; transcriptionText: string; familyId: string; userId: string }, { ctx }) => {
    const supabase = createSupabaseClient();
    const bedrock = createBedrockClient();

    // Fallback prompts in case AI generation fails
    const fallbackPrompts = [
      "What's a story from your life you'd like to share?",
      "What's a meaningful memory you'd like to preserve?",
      "What's something you'd like future generations to know?",
      "What's a valuable lesson life has taught you?",
      "What's a memorable experience from your childhood?",
      "What's a tradition your family had that you loved?",
      "What's something you're grateful for?",
      "What advice would you give to your younger self?",
    ];

    let promptText: string;

    try {
      // Generate a contextual prompt using DeepSeek with JSON mode
      // DeepSeek requires explicit JSON request in the prompt when using response_format
      const completion = await bedrock.chat.completions.create({
        model: "qwen.qwen3-next-80b-a3b",
        messages: [
          {
            role: "system",
            content: `You are a family storytelling assistant. Generate thoughtful follow-up questions that encourage people to share more memories.

Your questions should be:
- Personal and conversational
- Open-ended (not yes/no)
- Related to the theme of their story
- Encouraging and warm
- Short (1-2 sentences max)

You must respond with valid JSON in this exact format:
{"prompt": "your follow-up question here"}`,
          },
          {
            role: "user",
            content: `Generate a follow-up question for this story: "${payload.transcriptionText}"

Respond with JSON only.`,
          },
        ],
        max_tokens: 150,
        temperature: 0.8,
        response_format: { type: "json_object" },
      });

      const message = completion.choices[0]?.message;
      
      if (!message || !message.content) {
        throw new Error("Empty response from AI");
      }

      console.log(`AI response (first 200 chars): ${message.content.substring(0, 200)}`);

      // Parse JSON response
      const jsonResponse = JSON.parse(message.content);
      const generatedPrompt = jsonResponse.prompt?.trim();

      if (generatedPrompt && generatedPrompt.length > 10) {
        promptText = generatedPrompt;
        console.log(`✓ AI-generated prompt: ${promptText}`);
      } else {
        throw new Error("Generated prompt was empty or too short");
      }
    } catch (error) {
      // Fallback to random prompt if AI generation fails
      console.warn(`AI prompt generation failed, using fallback:`, error);
      promptText = fallbackPrompts[Math.floor(Math.random() * fallbackPrompts.length)];
    }

    // Create the prompt in database
    const { data: newPrompt, error: promptError } = await supabase
      .from("prompts")
      .insert({
        text: promptText,
        family_id: payload.familyId,
        scheduled_for: null,
      })
      .select()
      .single();

    if (promptError || !newPrompt) {
      throw new Error(`Failed to create prompt: ${JSON.stringify(promptError)}`);
    }

    // Update the response with the new prompt_id
    const { error: updateError } = await supabase
      .from("responses")
      .update({ prompt_id: newPrompt.id })
      .eq("id", payload.responseId);

    if (updateError) {
      throw new Error(`Failed to update response: ${JSON.stringify(updateError)}`);
    }

    return {
      success: true,
      promptId: newPrompt.id,
      promptText,
      responseId: payload.responseId,
    };
  },
});
