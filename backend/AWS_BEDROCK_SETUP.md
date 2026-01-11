# AWS Bedrock Setup Guide

This guide explains how to set up AWS Bedrock with OpenAI-compatible API for the Family+ backend.

## Why AWS Bedrock?

AWS Bedrock provides access to foundation models (including OpenAI models) through a unified API. The OpenAI-compatible endpoint allows you to use the familiar OpenAI SDK while leveraging AWS infrastructure.

## Prerequisites

- AWS Account with Bedrock access
- AWS CLI installed and configured
- Access to AWS Bedrock in your region

## Step 1: Enable Bedrock Model Access

1. **Go to AWS Bedrock Console**:
   ```
   https://console.aws.amazon.com/bedrock/
   ```

2. **Select Your Region**:
   - Choose a region that supports Bedrock (e.g., `us-west-2`, `us-east-1`)
   - Note: Not all regions support all models

3. **Enable Model Access**:
   - Navigate to **Model access** in the left sidebar
   - Click **Manage model access**
   - Find and enable: `openai.gpt-oss-20b-1:0`
   - Click **Save changes**
   - Wait for status to change to "Access granted" (may take a few minutes)

## Step 2: Get AWS Bearer Token

### Option A: Using AWS CLI (Temporary Token)

Generate a temporary session token (valid for 1 hour):

```bash
aws sts get-session-token --duration-seconds 3600
```

This returns:

```json
{
  "Credentials": {
    "AccessKeyId": "ASIA...",
    "SecretAccessKey": "...",
    "SessionToken": "IQoJb3JpZ2...",
    "Expiration": "2024-01-11T15:00:00Z"
  }
}
```

Use the `SessionToken` as your `AWS_BEARER_TOKEN_BEDROCK`.

### Option B: Using IAM Role (Production)

For production, use IAM roles with proper permissions:

1. **Create IAM Policy**:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ],
      "Resource": "arn:aws:bedrock:*::foundation-model/openai.gpt-oss-20b-1:0"
    }
  ]
}
```

2. **Attach Policy to IAM Role or User**

3. **Generate Token**:

```bash
aws sts assume-role \
  --role-arn arn:aws:iam::YOUR_ACCOUNT_ID:role/YOUR_ROLE_NAME \
  --role-session-name bedrock-session
```

### Option C: Using AWS SDK (Automatic Token Refresh)

For long-running applications, use AWS SDK to automatically refresh tokens:

```typescript
import { BedrockRuntimeClient } from "@aws-sdk/client-bedrock-runtime";
import { fromEnv } from "@aws-sdk/credential-providers";

const client = new BedrockRuntimeClient({
  region: "us-west-2",
  credentials: fromEnv(),
});
```

## Step 3: Configure Environment Variables

### Local Development

Add to `backend/.dev.vars`:

```bash
AWS_BEARER_TOKEN_BEDROCK=your-session-token-here
AWS_REGION=us-west-2
```

### Cloudflare Workers (Production)

```bash
wrangler secret put AWS_BEARER_TOKEN_BEDROCK
wrangler secret put AWS_REGION
```

### Trigger.dev

1. Go to https://cloud.trigger.dev
2. Select your project
3. Navigate to **Settings** → **Environment Variables**
4. Add:
   - `AWS_BEARER_TOKEN_BEDROCK` = your token
   - `AWS_REGION` = your region (e.g., `us-west-2`)

## Step 4: Test the Integration

### Test Locally

```bash
# Start the dev server
npm run dev

# In another terminal, trigger a test task
npx trigger.dev@latest dev
```

### Test with curl

```bash
curl -X POST http://localhost:8787/responses \
  -H "Content-Type: application/json" \
  -d '{
    "transcriptionText": "I remember when I was a kid, we used to go fishing every summer.",
    "familyId": "your-family-uuid",
    "userId": "your-user-uuid"
  }'
```

### Verify in Logs

You should see:

```
✓ AI-generated prompt: What was your favorite part about those fishing trips?
```

## Available Models

AWS Bedrock supports multiple OpenAI-compatible models:

| Model ID | Description | Context Window | Cost |
|----------|-------------|----------------|------|
| `openai.gpt-oss-20b-1:0` | Open-source GPT model | 8K tokens | Low |
| `anthropic.claude-v2` | Claude 2 (via Bedrock) | 100K tokens | Medium |
| `meta.llama2-70b-v1` | Llama 2 70B | 4K tokens | Low |

To change models, update `backend/trigger/prompt-task.ts`:

```typescript
model: "anthropic.claude-v2", // or any other model
```

## Troubleshooting

### Error: "Could not connect to Bedrock"

**Cause**: Invalid or expired token

**Solution**:
```bash
# Generate a new token
aws sts get-session-token --duration-seconds 3600

# Update .dev.vars with new token
```

### Error: "Model not found"

**Cause**: Model not enabled in your region

**Solution**:
1. Go to AWS Bedrock Console
2. Check **Model access**
3. Enable the model
4. Wait for "Access granted" status

### Error: "Access Denied"

**Cause**: IAM permissions not set

**Solution**:
1. Add Bedrock permissions to your IAM role/user
2. Ensure policy includes `bedrock:InvokeModel`
3. Verify resource ARN matches your model

### Error: "Region not supported"

**Cause**: Bedrock not available in your region

**Solution**:
- Change to a supported region (e.g., `us-west-2`, `us-east-1`)
- Update `AWS_REGION` environment variable

## Cost Optimization

### Tips to Reduce Costs

1. **Use Smaller Models**: `openai.gpt-oss-20b-1:0` is cheaper than GPT-4
2. **Limit Token Usage**: Set `max_tokens: 100` for short responses
3. **Cache Prompts**: Store common prompts in database
4. **Batch Requests**: Process multiple prompts in one call
5. **Use Fallbacks**: Fallback to preset prompts if AI fails

### Estimated Costs

For 1,000 prompt generations per month:

- **AWS Bedrock**: ~$0.50 - $2.00/month
- **OpenAI GPT-4**: ~$10 - $30/month

## Security Best Practices

1. **Never Commit Tokens**: Add `.dev.vars` to `.gitignore`
2. **Rotate Tokens**: Generate new tokens regularly
3. **Use IAM Roles**: Prefer IAM roles over access keys
4. **Limit Permissions**: Only grant `bedrock:InvokeModel`
5. **Monitor Usage**: Set up CloudWatch alerts for unusual activity

## Alternative: Using OpenAI Directly

If you prefer to use OpenAI's API directly instead of AWS Bedrock:

1. **Update `backend/trigger/prompt-task.ts`**:

```typescript
// Remove AWS Bedrock configuration
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

// Update model
model: "gpt-4o-mini",
```

2. **Set Environment Variable**:

```bash
# .dev.vars
OPENAI_API_KEY=sk-...
```

3. **Deploy**:

```bash
wrangler secret put OPENAI_API_KEY
```

## Support

- **AWS Bedrock Docs**: https://docs.aws.amazon.com/bedrock/
- **OpenAI API Docs**: https://platform.openai.com/docs/api-reference
- **Trigger.dev Docs**: https://trigger.dev/docs

## Next Steps

1. ✅ Enable Bedrock model access
2. ✅ Generate AWS bearer token
3. ✅ Configure environment variables
4. ✅ Test locally with `npm run dev`
5. ✅ Deploy to production with `npm run deploy`
6. ✅ Monitor usage in AWS CloudWatch
