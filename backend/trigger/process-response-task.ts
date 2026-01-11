import { task } from "@trigger.dev/sdk";
import { createStoryTask } from "./story-task";

/**
 * Process a text response: generate prompt → create story → trigger quote + response-level tasks
 * This is the main entry point that chains the background tasks
 *
 * Response-level embedding and wisdom tagging happens AFTER this task
 * via transcribe-response-task.ts for audio or directly for text responses
 */
export const processResponseTask = task({
  id: "process-text-response",
  description: "Auto-generate prompt and story for a text response, then trigger quote generation",
  retry: {
    maxAttempts: 3,
    factor: 2,
    minTimeoutInMs: 1000,
    maxTimeoutInMs: 10000,
  },
  run: async (payload: { responseId: string; transcriptionText: string; familyId: string; userId: string }, { ctx }) => {
    // Step 1: Generate prompt text from transcription (AI-generated question)
    const promptText = await generatePromptFromText(payload.transcriptionText);

    // Step 2: Create story with embedded prompt text
    const storyData = await createStoryTask.triggerAndWait({
      responseId: payload.responseId,
      promptText: promptText,
      familyId: payload.familyId,
      transcriptionText: payload.transcriptionText,
    });

    if (!storyData.ok) {
      throw new Error(`Story creation failed: ${storyData.error}`);
    }

    const storyId = storyData.output.storyId;
    console.log(`[ProcessResponse] Story created: ${storyId}, now triggering quote and wisdom tasks...`);

    // Step 3: Trigger quote generation for the response
    try {
      const { generateQuoteTask } = await import("./quote-task");
      const quoteHandle = await generateQuoteTask.trigger({
        responseId: payload.responseId,
        storyId: storyId,
        triggeredBy: "response.transcribed",
      });
      console.log(`[ProcessResponse] ✅ Quote generation triggered: ${quoteHandle.id}`);
    } catch (error) {
      console.error(`[ProcessResponse] ❌ Failed to trigger quote generation:`, error);
    }

    // Step 4: Trigger response-level embedding and wisdom tagging
    try {
      const { embedResponseTask } = await import("./response-embed-task");
      await embedResponseTask.trigger({
        responseId: payload.responseId,
        triggeredBy: "response.transcribed",
      });

      const { tagResponseWisdomTask } = await import("./response-tag-task");
      await tagResponseWisdomTask.trigger({
        responseId: payload.responseId,
        triggeredBy: "response.transcribed",
      });

      console.log(`[ProcessResponse] ✅ Response-level embedding and wisdom tagging triggered`);
    } catch (error) {
      console.error(`[ProcessResponse] ❌ Failed to trigger response-level tasks:`, error);
    }

    return {
      success: true,
      responseId: payload.responseId,
      storyId: storyId,
    };
  },
});

// Helper function to generate prompt text from transcription
async function generatePromptFromText(transcriptionText: string): string {
  const OpenAI = require("openai");
  const awsBedrockToken = process.env.AWS_BEARER_TOKEN_BEDROCK!;
  const awsRegion = process.env.AWS_REGION || "us-east-1";

  const bedrock = new OpenAI({
    baseURL: `https://bedrock-runtime.${awsRegion}.amazonaws.com/openai/v1`,
    apiKey: awsBedrockToken,
  });

  const fallbackPrompts = [
    "What's a story from your life you'd like to share?",
    "What's a meaningful memory you'd like to preserve?",
    "What's something you'd like future generations to know?",
  ];

  try {
    const completion = await bedrock.chat.completions.create({
      model: "qwen.qwen3-next-80b-a3b",
      messages: [
        {
          role: "system",
          content: `Generate a thoughtful follow-up question for this story. Respond with JSON: {"prompt": "your question here"}`,
        },
        {
          role: "user",
          content: `Generate a follow-up question for: "${transcriptionText}"`,
        },
      ],
      max_tokens: 150,
      temperature: 0.8,
      response_format: { type: "json_object" },
    });

    const message = completion.choices[0]?.message;
    if (message?.content) {
      const jsonResponse = JSON.parse(message.content);
      const prompt = jsonResponse.prompt?.trim();
      if (prompt && prompt.length > 10) {
        return prompt;
      }
    }
  } catch (error) {
    console.warn(`Prompt generation failed, using fallback:`, error);
  }

  return fallbackPrompts[Math.floor(Math.random() * fallbackPrompts.length)];
}
