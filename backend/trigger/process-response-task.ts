import { task } from "@trigger.dev/sdk";
import { generatePromptTask } from "./prompt-task";
import { createStoryTask } from "./story-task";

/**
 * Process a text response: generate prompt → create story
 * This is the main entry point that chains the background tasks
 */
export const processResponseTask = task({
  id: "process-text-response",
  description: "Auto-generate prompt and story for a text response",
  retry: {
    maxAttempts: 3,
    factor: 2,
    minTimeoutInMs: 1000,
    maxTimeoutInMs: 10000,
  },
  run: async (payload: { responseId: string; transcriptionText: string; familyId: string; userId: string }, { ctx }) => {
    // Step 1: Generate prompt from transcription (triggerAndWait for v3)
    const promptData = await generatePromptTask.triggerAndWait({
      responseId: payload.responseId,
      transcriptionText: payload.transcriptionText,
      familyId: payload.familyId,
      userId: payload.userId,
    });

    if (!promptData.ok) {
      throw new Error(`Prompt generation failed: ${promptData.error}`);
    }

    // Step 2: Create story with the new prompt (triggerAndWait for v3)
    const storyData = await createStoryTask.triggerAndWait({
      responseId: payload.responseId,
      promptId: promptData.output.promptId,
      familyId: payload.familyId,
      transcriptionText: payload.transcriptionText, // Pass transcription for title generation
    });

    if (!storyData.ok) {
      throw new Error(`Story creation failed: ${storyData.error}`);
    }

    return {
      success: true,
      responseId: payload.responseId,
      promptId: promptData.output.promptId,
      storyId: storyData.output.storyId,
    };
  },
});
