# Quick Start Guide - Backend Setup

Get the Family+ backend running in 5 minutes!

## Prerequisites

- Node.js 18+ installed
- AWS account with Bedrock access
- Supabase project set up

## Step 1: Install Dependencies (30 seconds)

```bash
cd backend
npm install
```

## Step 2: Configure Environment (2 minutes)

### Copy the template:
```bash
cp .dev.vars.example .dev.vars
```

### Edit `.dev.vars` with your credentials:

```bash
# Get from Supabase Dashboard → Settings → API
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Get AWS Bearer Token (see below)
AWS_BEARER_TOKEN_BEDROCK=your-token-here
AWS_REGION=us-west-2

# Optional: Twilio (for Elder phone calls)
twilio_account_sid=ACxxxxx
twilio_auth_token=xxxxx
```

### Get AWS Bearer Token (Quick Method):

```bash
# Install AWS CLI if not installed
brew install awscli  # macOS
# or: sudo apt install awscli  # Linux

# Configure AWS CLI
aws configure

# Generate token (valid for 1 hour)
aws sts get-session-token --duration-seconds 3600
```

Copy the `SessionToken` value to `AWS_BEARER_TOKEN_BEDROCK`.

## Step 3: Enable AWS Bedrock Model (1 minute)

1. Go to: https://console.aws.amazon.com/bedrock/
2. Click **Model access** in sidebar
3. Click **Manage model access**
4. Enable: `openai.gpt-oss-20b-1:0`
5. Click **Save changes**

## Step 4: Start Development Servers (1 minute)

### Terminal 1 - Cloudflare Workers:
```bash
npm run dev
```

### Terminal 2 - Trigger.dev:
```bash
npx trigger.dev@latest dev
```

You should see:
```
✓ Connected to Trigger.dev
✓ Watching for changes...
```

## Step 5: Test It! (30 seconds)

### Test the API:
```bash
curl http://localhost:8787/
```

Expected: `{"message":"Family+ API is running"}`

### Test a Background Task:

```bash
curl -X POST http://localhost:8787/responses \
  -H "Content-Type: application/json" \
  -d '{
    "transcriptionText": "I remember my first day of school...",
    "familyId": "00000000-0000-0000-0000-000000000000",
    "userId": "00000000-0000-0000-0000-000000000000"
  }'
```

Watch Terminal 2 for:
```
○ generate-prompt-from-transcription | Started
✓ AI-generated prompt: What do you remember most about that first day?
○ generate-prompt-from-transcription | Success (2.1s)
```

## ✅ You're Done!

The backend is now running with:
- ✅ Cloudflare Workers API
- ✅ Trigger.dev background tasks
- ✅ AWS Bedrock AI prompt generation
- ✅ Supabase database connection

## Next Steps

1. **Deploy to Production**:
   ```bash
   npm run deploy
   npx trigger.dev@latest deploy
   ```

2. **Set Production Secrets**:
   ```bash
   wrangler secret put SUPABASE_URL
   wrangler secret put SUPABASE_KEY
   wrangler secret put AWS_BEARER_TOKEN_BEDROCK
   wrangler secret put AWS_REGION
   ```

3. **Configure Trigger.dev**:
   - Go to https://cloud.trigger.dev
   - Add environment variables in Settings

## Troubleshooting

### "AWS Bedrock connection failed"
- Generate a new token: `aws sts get-session-token --duration-seconds 3600`
- Update `.dev.vars` with new token

### "Model not found"
- Enable model in AWS Bedrock console
- Wait for "Access granted" status

### "Trigger.dev not connecting"
- Check you're running `npx trigger.dev@latest dev`
- Verify internet connection
- Check Trigger.dev status: https://status.trigger.dev

### "Supabase connection failed"
- Verify `SUPABASE_URL` and `SUPABASE_KEY` in `.dev.vars`
- Check Supabase project is running
- Verify API key has correct permissions

## Common Commands

```bash
# Start dev server
npm run dev

# Start Trigger.dev
npx trigger.dev@latest dev

# Deploy to Cloudflare
npm run deploy

# Deploy Trigger.dev tasks
npx trigger.dev@latest deploy

# Run tests
npm test

# View logs
wrangler tail
```

## Documentation

- 📖 Full README: `backend/README.md`
- 🔧 AWS Setup: `backend/AWS_BEDROCK_SETUP.md`
- 📝 Fix Summary: `TRIGGER_FIXES_SUMMARY.md`

## Need Help?

- Trigger.dev Docs: https://trigger.dev/docs
- Cloudflare Workers: https://developers.cloudflare.com/workers/
- AWS Bedrock: https://docs.aws.amazon.com/bedrock/
- Supabase: https://supabase.com/docs

---

**Happy Coding! 🚀**
