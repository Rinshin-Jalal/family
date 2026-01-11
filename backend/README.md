# Family+ Backend

Cloudflare Workers backend with Trigger.dev background tasks for the Family+ storytelling platform.

## Tech Stack

- **Runtime**: Cloudflare Workers
- **Framework**: Hono
- **Database**: Supabase (PostgreSQL)
- **Background Jobs**: Trigger.dev v3
- **AI**: AWS Bedrock (OpenAI-compatible API)

## Setup

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure Environment Variables

#### Local Development (`.dev.vars`)

Copy the example file and fill in your credentials:

```bash
cp .dev.vars.example .dev.vars
```

Edit `.dev.vars` with your actual values:

```bash
# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-anon-key-here

# AWS Bedrock Configuration (OpenAI-compatible API)
AWS_BEARER_TOKEN_BEDROCK=your-aws-bearer-token-here
AWS_REGION=us-west-2

# Twilio Configuration (for Elder phone calls)
twilio_account_sid=your-twilio-account-sid
twilio_auth_token=your-twilio-auth-token
```

#### Production (Cloudflare Secrets)

Set secrets for production deployment:

```bash
wrangler secret put SUPABASE_URL
wrangler secret put SUPABASE_KEY
wrangler secret put AWS_BEARER_TOKEN_BEDROCK
wrangler secret put AWS_REGION
wrangler secret put twilio_account_sid
wrangler secret put twilio_auth_token
```

#### Trigger.dev Environment Variables

Set environment variables in your Trigger.dev dashboard:

1. Go to https://cloud.trigger.dev
2. Select your project
3. Navigate to **Settings** → **Environment Variables**
4. Add the following variables:
   - `SUPABASE_URL`
   - `SUPABASE_KEY`
   - `AWS_BEARER_TOKEN_BEDROCK`
   - `AWS_REGION`

### 3. Start Development Server

```bash
npm run dev
```

This starts the Cloudflare Workers dev server at `http://localhost:8787`

### 4. Run Trigger.dev Tasks Locally

In a separate terminal:

```bash
npx trigger.dev@latest dev
```

This starts the Trigger.dev local development server for testing background tasks.

## AWS Bedrock Setup

The backend uses AWS Bedrock with OpenAI-compatible API for AI prompt generation.

### Getting AWS Bedrock Token

1. **Enable Bedrock in AWS Console**:
   - Go to AWS Bedrock console
   - Enable model access for `openai.gpt-oss-20b-1:0`
   - Note your AWS region (e.g., `us-west-2`)

2. **Generate Bearer Token**:
   ```bash
   aws sts get-session-token --duration-seconds 3600
   ```

3. **Set Environment Variable**:
   ```bash
   export AWS_BEARER_TOKEN_BEDROCK="your-token-here"
   ```

### Using OpenAI Instead (Optional)

If you prefer to use OpenAI directly instead of AWS Bedrock:

1. Update `backend/trigger/prompt-task.ts`:
   ```typescript
   // Change baseURL to OpenAI's endpoint
   const openai = new OpenAI({
     apiKey: process.env.OPENAI_API_KEY,
   });
   
   // Change model to OpenAI model
   model: "gpt-4o-mini",
   ```

2. Set `OPENAI_API_KEY` in `.dev.vars` and Trigger.dev

## Available Scripts

- `npm run dev` - Start Cloudflare Workers dev server
- `npm run deploy` - Deploy to Cloudflare Workers
- `npm test` - Run tests
- `npm run test:watch` - Run tests in watch mode
- `npm run test:coverage` - Generate test coverage report

## Background Tasks (Trigger.dev)

The backend uses Trigger.dev v3 for background task processing:

### Tasks

1. **`generate-prompt-from-transcription`** (`trigger/prompt-task.ts`)
   - Generates AI follow-up questions from story transcriptions
   - Uses AWS Bedrock with OpenAI-compatible API
   - Falls back to preset prompts if AI fails

2. **`create-story-from-response`** (`trigger/story-task.ts`)
   - Creates a story entry from a response
   - Links response to prompt and family

3. **`process-text-response`** (`trigger/process-response-task.ts`)
   - Main orchestrator task
   - Chains prompt generation → story creation

### Triggering Tasks

Tasks are triggered from the main API routes:

```typescript
import { tasks } from "@trigger.dev/sdk/v3";

// Trigger a task
await tasks.trigger("process-text-response", {
  responseId: "uuid",
  transcriptionText: "The user's story...",
  familyId: "uuid",
  userId: "uuid",
});
```

### Monitoring Tasks

- **Local**: View logs in the terminal running `npx trigger.dev dev`
- **Production**: View in Trigger.dev dashboard at https://cloud.trigger.dev

## API Routes

- `POST /responses` - Submit a new story response
- `GET /stories` - Get family stories
- `GET /prompts` - Get family prompts
- `POST /wisdom` - Submit wisdom/advice
- `GET /locations` - Get family locations

## Deployment

### Deploy to Cloudflare Workers

```bash
npm run deploy
```

### Deploy Trigger.dev Tasks

```bash
npx trigger.dev@latest deploy
```

## Troubleshooting

### "Could not find the 'created_by' column"

This error occurs if you're using an old database schema. Run the latest migration:

```bash
cd ../supabase
supabase db reset
```

### "waitForFinished is not a function"

This error occurs if you're mixing Trigger.dev v2 and v3 APIs. Make sure to use `triggerAndWait()` instead of `trigger()` + `waitForFinished()`.

### AWS Bedrock Authentication Errors

- Ensure your AWS bearer token is valid and not expired
- Check that you have access to the Bedrock model in your region
- Verify the region matches your Bedrock setup

### Trigger.dev Tasks Not Running

- Ensure `npx trigger.dev dev` is running locally
- Check environment variables are set in Trigger.dev dashboard
- Verify your Trigger.dev project ID in `trigger.config.ts`

## Project Structure

```
backend/
├── src/
│   ├── index.ts              # Main Hono app entry point
│   ├── routes/               # API route handlers
│   ├── ai/                   # AI/LLM utilities
│   ├── events/               # Event handlers
│   ├── middleware/           # Auth middleware
│   └── utils/                # Utility functions
├── trigger/
│   ├── prompt-task.ts        # AI prompt generation task
│   ├── story-task.ts         # Story creation task
│   └── process-response-task.ts  # Main orchestrator
├── .dev.vars                 # Local environment variables (gitignored)
├── .dev.vars.example         # Environment variable template
├── package.json              # Dependencies
├── trigger.config.ts         # Trigger.dev configuration
├── tsconfig.json             # TypeScript configuration
└── wrangler.toml             # Cloudflare Workers configuration
```

## Security Notes

- Never commit `.dev.vars` to git
- Use Cloudflare secrets for production environment variables
- Use Trigger.dev environment variables for background tasks
- All database access is protected by Supabase RLS policies
- Audio files stored in R2 with private access

## Support

For issues or questions:
- Check the [Trigger.dev docs](https://trigger.dev/docs)
- Check the [Cloudflare Workers docs](https://developers.cloudflare.com/workers/)
- Check the [Supabase docs](https://supabase.com/docs)
