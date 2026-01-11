import { tasks } from "@trigger.dev/sdk";

// Global failure logging
tasks.onFailure(async ({ error }) => {
  console.error("[Trigger.dev] Task failed:", error);
});

// Global success logging
tasks.onSuccess(async ({ output }) => {
  console.log("[Trigger.dev] Task succeeded:", output);
});
