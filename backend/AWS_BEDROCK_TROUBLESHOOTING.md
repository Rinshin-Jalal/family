# AWS Bedrock Troubleshooting Guide

## Common Issues with AWS Bedrock OpenAI-Compatible Endpoint

### Issue 1: `<reasoning>` Tags in Response

**Symptom**:
```
SyntaxError: Unexpected token '<', "<reasoning"... is not valid JSON
```

**Root Cause**: AWS Bedrock's OpenAI-compatible endpoint may not fully support:
- `response_format: { type: "json_schema" }` (Structured Outputs)
- `response_format: { type: "json_object" }` (JSON Mode)

**Solution**: Use strong prompt engineering + robust parsing

```typescript
// ❌ Don't rely on response_format alone
response_format: { type: "json_object" }

// ✅ Use strong prompts + extraction
messages: [{
  role: "system",
  content: `CRITICAL: Respond with ONLY JSON: {"prompt": "..."}
  NO reasoning, NO explanations, NO extra text.`
}]

// ✅ Extract JSON robustly
const jsonMatch = response.match(/\{[^{}]*"prompt"[^{}]*\}/);
const json = JSON.parse(jsonMatch[0]);
```

---

### Issue 2: Model Not Found

**Symptom**:
```
Error: Model openai.gpt-oss-20b-1:0 not found
```

**Causes**:
1. Model not enabled in AWS Bedrock console
2. Wrong region
3. Wrong model ID

**Solution**:

1. **Check Model Access**:
   ```bash
   aws bedrock list-foundation-models --region us-east-1
   ```

2. **Enable Model** in AWS Console:
   - Go to https://console.aws.amazon.com/bedrock/
   - Click "Model access"
   - Enable the model
   - Wait for "Access granted"

3. **Try Different Models**:
   ```typescript
   // Option 1: OpenAI-compatible
   model: "openai.gpt-oss-20b-1:0"
   
   // Option 2: Anthropic Claude
   model: "anthropic.claude-v2"
   
   // Option 3: Meta Llama
   model: "meta.llama2-70b-v1"
   ```

---

### Issue 3: Authentication Errors

**Symptom**:
```
Error: Invalid bearer token
Error: Access denied
```

**Solutions**:

#### Option A: Refresh Token (Temporary - 1 hour)
```bash
aws sts get-session-token --duration-seconds 3600
```

Copy `SessionToken` to `AWS_BEARER_TOKEN_BEDROCK`.

#### Option B: Use AWS SDK (Automatic Refresh)

Instead of OpenAI SDK with bearer token, use AWS SDK directly:

```typescript
import { BedrockRuntimeClient, InvokeModelCommand } from "@aws-sdk/client-bedrock-runtime";
import { fromEnv } from "@aws-sdk/credential-providers";

const client = new BedrockRuntimeClient({
  region: process.env.AWS_REGION || "us-east-1",
  credentials: fromEnv(), // Automatically refreshes
});

const command = new InvokeModelCommand({
  modelId: "anthropic.claude-v2",
  contentType: "application/json",
  accept: "application/json",
  body: JSON.stringify({
    prompt: "\n\nHuman: Generate a question\n\nAssistant:",
    max_tokens_to_sample: 150,
    temperature: 0.8,
  }),
});

const response = await client.send(command);
const result = JSON.parse(new TextDecoder().decode(response.body));
```

---

### Issue 4: Response Format Not Supported

**Symptom**: Model ignores `response_format` and returns unstructured text

**Why**: AWS Bedrock's OpenAI-compatible endpoint is a wrapper and may not support all OpenAI features.

**Solution**: Don't rely on `response_format`, use prompt engineering:

```typescript
// ❌ May not work with Bedrock
const completion = await bedrock.chat.completions.create({
  model: "openai.gpt-oss-20b-1:0",
  messages: [...],
  response_format: { type: "json_object" }, // Ignored!
});

// ✅ Works with Bedrock
const completion = await bedrock.chat.completions.create({
  model: "openai.gpt-oss-20b-1:0",
  messages: [
    {
      role: "system",
      content: `You MUST respond with ONLY this JSON format:
      {"prompt": "your question"}
      
      NO reasoning, NO explanations, NO extra text.
      
      Examples:
      {"prompt": "What happened next?"}
      {"prompt": "How did you feel?"}
      
      Respond with ONLY the JSON object.`
    }
  ],
});

// Then extract JSON robustly
const jsonMatch = response.match(/\{[^{}]*"prompt"[^{}]*\}/);
```

---

### Issue 5: Inconsistent Responses

**Symptom**: Sometimes returns JSON, sometimes returns reasoning

**Solution**: Implement robust extraction + fallback:

```typescript
function extractPrompt(response: string): string {
  // Try 1: Parse as-is
  try {
    const json = JSON.parse(response);
    if (json.prompt) return json.prompt;
  } catch {}

  // Try 2: Remove markdown code blocks
  if (response.includes("```")) {
    const match = response.match(/```(?:json)?\s*(\{[\s\S]*?\})\s*```/);
    if (match) {
      try {
        const json = JSON.parse(match[1]);
        if (json.prompt) return json.prompt;
      } catch {}
    }
  }

  // Try 3: Extract JSON object
  const jsonMatch = response.match(/\{[^{}]*"prompt"[^{}]*\}/);
  if (jsonMatch) {
    try {
      const json = JSON.parse(jsonMatch[0]);
      if (json.prompt) return json.prompt;
    } catch {}
  }

  // Try 4: Extract quoted text after "prompt":
  const promptMatch = response.match(/"prompt"\s*:\s*"([^"]+)"/);
  if (promptMatch) {
    return promptMatch[1];
  }

  throw new Error("Could not extract prompt from response");
}
```

---

## Alternative: Use Native AWS Bedrock API

If OpenAI-compatible endpoint is too unreliable, use native Bedrock API:

### Install AWS SDK:
```bash
npm install @aws-sdk/client-bedrock-runtime
```

### Use Anthropic Claude (Recommended):

```typescript
import { BedrockRuntimeClient, InvokeModelCommand } from "@aws-sdk/client-bedrock-runtime";

const client = new BedrockRuntimeClient({
  region: "us-east-1",
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID!,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY!,
  },
});

async function generatePrompt(storyText: string): Promise<string> {
  const prompt = `\n\nHuman: You are a family storytelling assistant. Based on this story, generate a thoughtful follow-up question:

Story: "${storyText}"

Respond with ONLY a JSON object: {"prompt": "your question"}

\n\nAssistant:`;

  const command = new InvokeModelCommand({
    modelId: "anthropic.claude-v2",
    contentType: "application/json",
    accept: "application/json",
    body: JSON.stringify({
      prompt: prompt,
      max_tokens_to_sample: 150,
      temperature: 0.8,
    }),
  });

  const response = await client.send(command);
  const result = JSON.parse(new TextDecoder().decode(response.body));
  
  // Claude returns: { completion: "..." }
  const completion = result.completion;
  
  // Extract JSON
  const jsonMatch = completion.match(/\{[^{}]*"prompt"[^{}]*\}/);
  if (jsonMatch) {
    const json = JSON.parse(jsonMatch[0]);
    return json.prompt;
  }
  
  throw new Error("Could not extract prompt");
}
```

---

## Recommended Approach

### Option 1: OpenAI Direct (Most Reliable)

If you have an OpenAI API key, use it directly:

```typescript
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

const completion = await openai.chat.completions.create({
  model: "gpt-4o-mini",
  messages: [...],
  response_format: {
    type: "json_schema",
    json_schema: {
      name: "prompt_response",
      strict: true,
      schema: {
        type: "object",
        properties: { prompt: { type: "string" } },
        required: ["prompt"],
        additionalProperties: false,
      }
    }
  }
});
```

**Pros**: Structured Outputs work perfectly  
**Cons**: More expensive (~$0.15 per 1M tokens vs $0.01)

### Option 2: AWS Bedrock Native API (Most Reliable on AWS)

```typescript
import { BedrockRuntimeClient, InvokeModelCommand } from "@aws-sdk/client-bedrock-runtime";

// Use Claude or Llama with native API
```

**Pros**: Reliable, cheap, automatic auth refresh  
**Cons**: Different API for each model

### Option 3: AWS Bedrock OpenAI-Compatible (Current)

```typescript
const bedrock = new OpenAI({
  baseURL: `https://bedrock-runtime.${region}.amazonaws.com/openai/v1`,
  apiKey: bearerToken,
});

// Use strong prompts + robust extraction
```

**Pros**: Familiar OpenAI SDK, cheap  
**Cons**: May not support all features, requires robust extraction

---

## Testing Your Setup

### Test 1: Check Model Access
```bash
aws bedrock list-foundation-models --region us-east-1 --query 'modelSummaries[?contains(modelId, `openai`)].modelId'
```

### Test 2: Test Direct API Call
```bash
curl -X POST "https://bedrock-runtime.us-east-1.amazonaws.com/openai/v1/chat/completions" \
  -H "Authorization: Bearer $AWS_BEARER_TOKEN_BEDROCK" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "openai.gpt-oss-20b-1:0",
    "messages": [{"role": "user", "content": "Say hello in JSON: {\"message\": \"...\"}"}],
    "max_tokens": 50
  }'
```

### Test 3: Test with Code
```typescript
// Add to your task for debugging
console.log("Testing Bedrock connection...");
const testResponse = await bedrock.chat.completions.create({
  model: "openai.gpt-oss-20b-1:0",
  messages: [{ role: "user", content: "Say hello" }],
  max_tokens: 10,
});
console.log("Test response:", testResponse.choices[0].message.content);
```

---

## Current Implementation Status

Our current implementation (`backend/trigger/prompt-task.ts`):

✅ Uses OpenAI SDK with AWS Bedrock endpoint  
✅ Strong prompt engineering for JSON output  
✅ Robust JSON extraction (handles markdown, extra text)  
✅ Detailed logging of raw responses  
✅ Graceful fallback to preset prompts  
❌ Does NOT use `response_format` (not reliable with Bedrock)  

**Next Steps**:
1. Test with current implementation
2. Check logs for raw AI responses
3. If still failing, switch to native AWS SDK
4. Or switch to OpenAI direct API

---

## Support Resources

- **AWS Bedrock Docs**: https://docs.aws.amazon.com/bedrock/
- **OpenAI API Docs**: https://platform.openai.com/docs/api-reference
- **Our Implementation**: `backend/trigger/prompt-task.ts`
- **Error Logs**: Check Trigger.dev dashboard

---

## Quick Fixes

### If you keep getting `<reasoning>` tags:

1. **Add more examples** to the system prompt
2. **Remove `response_format`** entirely (may not be supported)
3. **Use regex extraction** to pull out JSON
4. **Switch to OpenAI direct** for guaranteed Structured Outputs
5. **Use fallback prompts** (current behavior - works fine!)

### If authentication keeps failing:

1. **Use AWS SDK** instead of bearer tokens
2. **Set up IAM role** for automatic refresh
3. **Use environment credentials**: `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY`

### If model not found:

1. **Check region** matches where model is enabled
2. **Enable model** in AWS Bedrock console
3. **Try different model** (Claude, Llama, etc.)
