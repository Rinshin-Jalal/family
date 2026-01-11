# Structured Outputs Guide - Guaranteed Valid JSON

## The Problem

Without structured outputs, AI models sometimes return reasoning or explanatory text instead of just the answer:

### ❌ Bad Output (Without JSON Mode):
```json
{
  "promptText": "<reasoning>User wants a follow-up question. Need to create something personal and open-ended. So something like: \"What made that day feel especially bad, and how did you cope with it?\"</reasoning>"
}
```

### ✅ Good Output (With JSON Mode):
```json
{
  "prompt": "What made that day feel especially bad, and how did you cope with it?"
}
```

## The Solution: Structured Outputs (Better than JSON Mode!)

### Why Structured Outputs > JSON Mode?

| Feature | JSON Mode | Structured Outputs |
|---------|-----------|-------------------|
| **Guarantees valid JSON** | ❌ No | ✅ Yes |
| **Enforces schema** | ❌ No | ✅ Yes |
| **Prevents extra fields** | ❌ No | ✅ Yes |
| **Type safety** | ❌ No | ✅ Yes |
| **Prevents reasoning tags** | ❌ No | ✅ Yes |

### Enable Structured Outputs in OpenAI SDK

```typescript
const completion = await openai.chat.completions.create({
  model: "openai.gpt-oss-20b-1:0",
  messages: [
    {
      role: "system",
      content: "You are a helpful assistant."
    },
    {
      role: "user",
      content: "Generate a question..."
    }
  ],
  response_format: {
    type: "json_schema", // 👈 Use json_schema, not json_object
    json_schema: {
      name: "prompt_response",
      strict: true, // 👈 Enforces strict schema validation
      schema: {
        type: "object",
        properties: {
          prompt: {
            type: "string",
            description: "The generated question",
          },
        },
        required: ["prompt"],
        additionalProperties: false, // 👈 No extra fields allowed
      },
    },
  },
});

// Parse the JSON response - guaranteed to match schema!
const jsonResponse = JSON.parse(completion.choices[0].message.content);
const prompt = jsonResponse.prompt;
```

## Key Requirements

### 1. Define Your JSON Schema
Create a strict JSON schema following the JSON Schema specification:

```typescript
const schema = {
  type: "object",
  properties: {
    prompt: {
      type: "string",
      description: "The generated question",
    },
  },
  required: ["prompt"],
  additionalProperties: false, // Critical: prevents extra fields
};
```

### 2. Set response_format with json_schema
```typescript
response_format: {
  type: "json_schema",
  json_schema: {
    name: "your_schema_name",
    strict: true, // Enforces strict validation
    schema: schema,
  },
}
```

### 3. Parse the Response
With structured outputs, parsing is guaranteed to succeed (unless network error):

```typescript
try {
  const jsonResponse = JSON.parse(responseText);
  const value = jsonResponse.prompt; // Guaranteed to exist!
} catch (error) {
  console.error("Unexpected error:", error);
  // Use fallback
}
```

## Common JSON Schemas

### Simple String Response
```json
{
  "prompt": "What's your favorite memory from that time?"
}
```

### Multiple Fields
```json
{
  "prompt": "Tell me more about that experience.",
  "category": "childhood",
  "sentiment": "positive"
}
```

### Array Response
```json
{
  "prompts": [
    "What happened next?",
    "How did that make you feel?",
    "What did you learn from that?"
  ]
}
```

### Nested Objects
```json
{
  "prompt": {
    "text": "What was the best part of that day?",
    "category": "happy_memories",
    "tags": ["childhood", "family"]
  }
}
```

## Best Practices

### ✅ DO:

1. **Always specify the exact JSON format** in the system prompt:
   ```typescript
   content: 'Respond with JSON: {"prompt": "your question"}'
   ```

2. **Use response_format** parameter:
   ```typescript
   response_format: { type: "json_object" }
   ```

3. **Parse and validate** the response:
   ```typescript
   const data = JSON.parse(response);
   if (!data.prompt) throw new Error("Invalid response");
   ```

4. **Handle parsing errors** gracefully:
   ```typescript
   try {
     const data = JSON.parse(response);
   } catch (error) {
     // Use fallback
   }
   ```

5. **Provide examples** in the system prompt:
   ```typescript
   content: `Respond with JSON like this example:
   {"prompt": "What was your favorite part?"}`
   ```

### ❌ DON'T:

1. **Don't forget to mention JSON** in the system prompt
2. **Don't skip validation** after parsing
3. **Don't assume the format** - always parse
4. **Don't use complex nested structures** unless necessary
5. **Don't forget error handling** for invalid JSON

## Example: Prompt Generation Task (Using Structured Outputs)

```typescript
const completion = await bedrock.chat.completions.create({
  model: "openai.gpt-oss-20b-1:0",
  messages: [
    {
      role: "system",
      content: `You are a family storytelling assistant.

Generate follow-up questions that are:
- Personal and conversational
- Open-ended (not yes/no)
- Warm and encouraging
- Short (1-2 sentences max)`,
    },
    {
      role: "user",
      content: `Generate a follow-up question for: "${storyText}"`,
    },
  ],
  max_tokens: 150,
  temperature: 0.8,
  response_format: {
    type: "json_schema",
    json_schema: {
      name: "prompt_response",
      strict: true,
      schema: {
        type: "object",
        properties: {
          prompt: {
            type: "string",
            description: "A thoughtful follow-up question",
          },
        },
        required: ["prompt"],
        additionalProperties: false,
      },
    },
  },
});

// Parse response - guaranteed valid!
const responseText = completion.choices[0]?.message?.content?.trim();
const jsonResponse = JSON.parse(responseText);
const prompt = jsonResponse.prompt;

console.log(`Generated prompt: ${prompt}`);
// Output: "Generated prompt: What made that memory so special to you?"
```

## Debugging JSON Responses

### Log the Raw Response
```typescript
const responseText = completion.choices[0]?.message?.content;
console.log("Raw AI response:", responseText);

try {
  const parsed = JSON.parse(responseText);
  console.log("Parsed JSON:", parsed);
} catch (error) {
  console.error("Failed to parse JSON:", error);
  console.error("Response was:", responseText);
}
```

### Common Issues

#### Issue 1: Response includes markdown code blocks
```
```json
{"prompt": "Question here"}
```
```

**Solution**: Strip markdown:
```typescript
const cleaned = responseText.replace(/```json\n?/g, '').replace(/```\n?/g, '');
const parsed = JSON.parse(cleaned);
```

#### Issue 2: Response includes extra text
```
Here's the JSON response:
{"prompt": "Question here"}
```

**Solution**: Extract JSON only:
```typescript
const jsonMatch = responseText.match(/\{.*\}/s);
if (jsonMatch) {
  const parsed = JSON.parse(jsonMatch[0]);
}
```

#### Issue 3: Invalid JSON syntax
```json
{prompt: "Missing quotes"}
```

**Solution**: Use JSON mode - it prevents this!

## Model Support

### Models that Support Structured Outputs:

✅ **OpenAI** (with `json_schema`):
- `gpt-4o` (2024-08-06+)
- `gpt-4o-mini` (2024-07-18+)

✅ **AWS Bedrock (OpenAI-compatible)**:
- `openai.gpt-oss-20b-1:0` - Supports structured outputs

⚠️ **Models with JSON Mode Only** (less strict):
- `gpt-4-turbo`
- `gpt-3.5-turbo-1106`

❌ **Models WITHOUT structured outputs**:
- Older GPT-3.5 models
- Some open-source models

### Fallback for Older Models

For models without structured outputs, use JSON mode with strong prompting:
```typescript
response_format: { type: "json_object" },
messages: [
  {
    role: "system",
    content: `CRITICAL: You MUST respond with ONLY valid JSON. 
No explanations, no reasoning, no extra text.
Format: {"prompt": "your question"}

DO NOT include anything except the JSON object.`
  }
]
```

## Testing JSON Mode

### Unit Test Example:

```typescript
import { describe, it, expect } from '@jest/globals';

describe('AI Prompt Generation', () => {
  it('should return valid JSON', async () => {
    const response = await generatePrompt("Test story");
    
    // Should be valid JSON
    expect(() => JSON.parse(response)).not.toThrow();
    
    // Should have required field
    const parsed = JSON.parse(response);
    expect(parsed.prompt).toBeDefined();
    expect(typeof parsed.prompt).toBe('string');
    expect(parsed.prompt.length).toBeGreaterThan(10);
  });
  
  it('should not include reasoning tags', async () => {
    const response = await generatePrompt("Test story");
    expect(response).not.toContain('<reasoning>');
    expect(response).not.toContain('</reasoning>');
  });
});
```

## Performance Impact

JSON mode has minimal performance impact:

- **Latency**: +0-50ms (negligible)
- **Token usage**: Similar or slightly less
- **Reliability**: Much higher (99%+ valid JSON)

## Summary

✅ **Always use Structured Outputs** (`json_schema`) for guaranteed valid JSON  
✅ **Define strict schemas** with `additionalProperties: false`  
✅ **Set `strict: true`** for schema enforcement  
✅ **No need for prompt engineering** - schema does the work  
✅ **Handle errors** gracefully with fallbacks  

### Quick Comparison

```typescript
// ❌ BAD: JSON Mode (can still return reasoning)
response_format: { type: "json_object" }

// ✅ GOOD: Structured Outputs (guaranteed schema match)
response_format: {
  type: "json_schema",
  json_schema: {
    name: "response",
    strict: true,
    schema: { /* your schema */ }
  }
}
```

This ensures your AI responses are **always** clean, parseable, and production-ready! 🚀
