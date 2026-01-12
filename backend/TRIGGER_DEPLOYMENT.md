# Trigger.dev Background Tasks Deployment Guide

## Overview

Family+ uses Trigger.dev v3 for background job processing. These tasks handle:
- Story transcription (Cartesia API)
- AI prompt generation (AWS Bedrock)
- Embedding generation (pgvector)
- Wisdom extraction and tagging
- Quote extraction
- Podcast generation

---

## Prerequisites

- Trigger.dev account (cloud.trigger.dev)
- Project ID: `proj_vdbanaagzxesesgrgmgvuz`
- Node.js environment
- FFmpeg support (for audio processing)

---

## Phase 1: Trigger.dev Project Setup

### 1.1 Link Project

```bash
cd backend

# Login to Trigger.dev
npx trigger.dev@latest login

# Verify project connection
npx trigger.dev@latest whoami

# Check project status
npx trigger.dev@latest info
```

### 1.2 Configure Project Settings

Edit `trigger.config.ts`:

```typescript
import { defineConfig } from "@trigger.dev/sdk/v3";
import { ffmpeg } from "@trigger.dev/build/extensions/core";

export default defineConfig({
  project: "proj_vdbanaagzxesesgrgmgvuz",
  runtime: "node",
  logLevel: "log",
  maxDuration: 3600, // 1 hour max
  retries: {
    enabledInDev: true,
    default: {
      maxAttempts: 3,
      minTimeoutInMs: 1000,
      maxTimeoutInMs: 10000,
      factor: 2,
      randomize: true,
    },
  },
  dirs: ["./trigger"],
  build: {
    extensions: [
      ffmpeg({ version: "7" }),
    ],
  },
});
```

---

## Phase 2: Environment Variables

### 2.1 Set in Trigger.dev Dashboard

1. Go to https://cloud.trigger.dev
2. Select project: **Family+ Backend**
3. Navigate to **Settings** → **Environment Variables**
4. Add the following:

| Variable | Required | Description |
|----------|----------|-------------|
| `SUPABASE_URL` | Yes | Supabase project URL |
| `SUPABASE_KEY` | Yes | Supabase service role key |
| `AWS_BEARER_TOKEN_BEDROCK` | Yes | AWS Bedrock bearer token |
| `AWS_REGION` | Yes | AWS region (us-west-2) |
| `CARTESIA_API_KEY` | Yes | Cartesia API key for transcription |
| `OPENAI_API_KEY` | Yes | OpenAI API key for embeddings |
| `twilio_account_sid` | No | Twilio account SID |
| `twilio_auth_token` | No | Twilio auth token |

### 2.2 Environment-Specific Variables

**Production** (set in Trigger.dev dashboard):
```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-service-role-key
AWS_BEARER_TOKEN_BEDROCK=your-production-token
AWS_REGION=us-west-2
CARTESIA_API_KEY=your-production-key
OPENAI_API_KEY=your-production-key
```

**Development** (set in `.dev.vars`):
```bash
SUPABASE_URL=https://your-dev-project.supabase.co
SUPABASE_KEY=your-dev-key
AWS_BEARER_TOKEN_BEDROCK=your-dev-token
AWS_REGION=us-west-2
CARTESIA_API_KEY=your-dev-key
OPENAI_API_KEY=your-dev-key
```

---

## Phase 3: Deploy Tasks

### 3.1 Deploy All Tasks

```bash
cd backend

# Deploy all trigger tasks
npx trigger.dev@latest deploy

# Expected output:
# ✓ Deployed generate-podcast-from-story
# ✓ Deployed process-text-response
# ✓ Deployed quote-generation
# ✓ Deployed response-embeddings
# ✓ Deployed response-tagging
# ✓ Deployed create-story-from-response
# ✓ Deployed transcribe-response
# ✓ Deployed wisdom-tagging
```

### 3.2 Verify Deployment

```bash
# List all deployed tasks
npx trigger.dev@latest tasks

# Expected output:
# generate-podcast-from-story
# process-text-response
# quote-generation
# response-embeddings
# response-tagging
# create-story-from-response
# transcribe-response
# wisdom-tagging
```

---

## Phase 4: Task Descriptions

### 4.1 Core Task Flow

```
transcribe-response
       ↓
response-embeddings
       ↓
response-tagging
       ↓
wisdom-tagging
       ↓
quote-generation
       ↓
create-story-from-response
       ↓
generate-podcast-from-story
```

### 4.2 Individual Tasks

#### `transcribe-response`
**File**: `trigger/transcribe-response-task.ts`
**Purpose**: Transcribe audio using Cartesia API
**Trigger**: Called when audio response is submitted
**Inputs**: Response ID, audio file URL
**Outputs**: Transcription text

#### `response-embeddings`
**File**: `trigger/response-embed-task.ts`
**Purpose**: Generate embeddings for semantic search
**Trigger**: After transcription completes
**Inputs**: Response ID, transcription text
**Outputs**: Embedding vector (stored in Supabase)

#### `response-tagging`
**File**: `trigger/response-tag-task.ts`
**Purpose**: Extract value tags from response
**Trigger**: After embeddings generated
**Inputs**: Response ID, transcription text
**Outputs**: Array of value tags

#### `wisdom-tagging`
**File**: `trigger/wisdom-tag-task.ts`
**Purpose**: Extract and tag wisdom/advice content
**Trigger**: After response tagging
**Inputs**: Wisdom ID, text content
**Outputs**: Wisdom tags and metadata

#### `quote-generation`
**File**: `trigger/quote-task.ts`
**Purpose**: Extract memorable quotes from stories
**Trigger**: After story creation
**Inputs**: Story ID, content
**Outputs**: Quote entries

#### `create-story-from-response`
**File**: `trigger/story-task.ts`
**Purpose**: Create story record from processed response
**Trigger**: After all tagging completes
**Inputs**: Response ID, family ID
**Outputs**: Story record

#### `generate-podcast-from-story`
**File**: `trigger/generate-podcast-task.ts`
**Purpose**: Generate audio podcast from story text
**Trigger**: Manual or scheduled
**Inputs**: Story ID
**Outputs**: Podcast audio file

#### `process-text-response`
**File**: `trigger/process-response-task.ts`
**Purpose**: Orchestrator for the entire pipeline
**Trigger**: New response submitted
**Inputs**: Response ID, transcription text, family ID
**Outputs**: Complete processed story

---

## Phase 5: Monitoring & Debugging

### 5.1 View Task Runs

```bash
# View recent runs
npx trigger.dev@latest runs

# View specific task
npx trigger.dev@latest runs --task=transcribe-response

# View run details
npx trigger.dev@latest runs --run=run_abc123
```

### 5.2 Dashboard Monitoring

1. Go to https://cloud.trigger.dev
2. Select **Family+ Backend** project
3. View:
   - **Runs**: Real-time task execution
   - **Tasks**: Task definitions and status
   - **Integrations**: External service connections
   - **Metrics**: Performance and error rates

### 5.3 Error Handling

Tasks are configured with automatic retries:
- **Max attempts**: 3
- **Backoff**: Exponential (1000ms to 10000ms)
- **Randomization**: Enabled

For failed tasks:
1. Check error logs in dashboard
2. Verify environment variables
3. Test external API access
4. Re-run with `triggerAndWait()`

---

## Phase 6: Testing

### 6.1 Local Development

```bash
# Terminal 1: Start local Trigger.dev
npx trigger.dev@latest dev

# Terminal 2: Start backend
npm run dev

# Terminal 3: Test task trigger
curl -X POST http://localhost:8787/test/trigger \
  -H "Content-Type: application/json" \
  -d '{"responseId": "test-123"}'
```

### 6.2 Production Testing

```bash
# Trigger a test task via API
curl -X POST https://your-worker.workers.dev/responses \
  -H "Content-Type: application/json" \
  -d '{
    "familyId": "test-family-id",
    "promptId": "test-prompt-id",
    "content": "Test story content",
    "mediaType": "text"
  }'

# Monitor in Trigger.dev dashboard
# Verify task chain completes successfully
```

---

## Phase 7: Scheduling (Optional)

### 7.1 Schedule Podcast Generation

```typescript
// In trigger/generate-podcast-task.ts
import { schedules } from "@trigger.dev/sdk/v3";

client.defineJob({
  id: "generate-daily-podcast",
  name: "Generate Daily Podcast",
  version: "0.0.1",
  trigger: schedules.interval({
    seconds: 86400, // Daily
  }),
  run: async (payload, io, ctx) => {
    // Fetch unprocessed stories
    // Generate podcasts
    // Send notifications
  },
});
```

### 7.2 Schedule Quote Delivery

```typescript
// Schedule daily quote delivery
client.defineJob({
  id: "daily-quote-delivery",
  name: "Deliver Daily Quote",
  version: "0.0.1",
  trigger: schedules.cron({
    cron: "0 9 * * *", // 9 AM daily
  }),
  run: async (payload, io, ctx) => {
    // Fetch daily quote
    // Send via email/notification
  },
});
```

---

## Troubleshooting

### Task doesn't appear after deploy
- Verify `trigger.config.ts` project ID
- Check `dirs` includes `./trigger`
- Re-run `npx trigger.dev deploy`

### Task fails immediately
- Check environment variables in dashboard
- Verify external API keys are valid
- Check task logs for specific error

### FFmpeg errors
- Ensure FFmpeg extension is in build config
- Verify audio file URLs are accessible
- Check audio format compatibility

### Supabase connection errors
- Verify SUPABASE_URL is correct
- Check SUPABASE_KEY has service role permissions
- Test connection: `psql $DATABASE_URL`

### Tasks not triggering
- Check worker is calling `tasks.trigger()`
- Verify task ID matches deployment
- Check Trigger.dev dashboard for registration

---

## Performance Optimization

### 7.1 Batch Processing

```typescript
// Process multiple responses in parallel
const runs = await Promise.all(
  responses.map(r =>
    tasks.triggerAndWait("process-text-response", {
      responseId: r.id,
      transcriptionText: r.content,
      familyId: r.familyId,
    })
  )
);
```

### 7.2 Queue Management

```typescript
// Implement priority queues
await tasks.trigger("process-text-response", {
  responseId: id,
  priority: "high", // For urgent stories
});
```

### 7.3 Caching Strategy

```typescript
// Cache embeddings for 24 hours
const cacheKey = `embeddings:${responseId}`;
const cached = await io.cache.get(cacheKey);
if (cached) return cached;
```

---

## Cost Optimization

Trigger.dev pricing is based on:
- **Compute time**: Task execution duration
- **API calls**: External service calls
- **Storage**: Logs and metadata

**Optimization tips**:
1. Minimize task duration
2. Batch API calls when possible
3. Use caching for repeated operations
4. Set appropriate timeouts
5. Monitor usage in dashboard

---

## Security Checklist

- [ ] Never commit `.dev.vars`
- [ ] Use service role keys in production
- [ ] Rotate API keys regularly
- [ ] Monitor for suspicious activity
- [ ] Implement rate limiting
- [ ] Validate all inputs
- [ ] Use encryption for sensitive data

---

## Resources

- [Trigger.dev Documentation](https://trigger.dev/docs)
- [Trigger.dev Dashboard](https://cloud.trigger.dev)
- [Background Jobs Guide](https://trigger.dev/docs/guides/background-jobs)
- [Task Monitoring](https://trigger.dev/docs/guides/monitoring)
