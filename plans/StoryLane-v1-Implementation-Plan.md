# StoryLane v1 Implementation Plan

**Version**: 1.0  
**Date**: January 8, 2026  
**Goal**: Ship v1 in 1 week (audio upload → transcription → quote cards → search)  
**Scope**: Simplified MVP focused on core value proposition

---

## Executive Summary

StoryLane v1 is a **1-week MVP** that captures and preserves family stories through audio uploads, AI transcription, and beautiful quote cards. The goal is to get users to upload 10+ stories to unlock the search feature, creating a "gaming mechanic" that drives engagement.

### Core Value Proposition
> "Most families accidentally stumble into their best memories. We help you intentionally create experiences that become the stories you'll tell forever."

### v1 Feature Set (Simplified)

| Feature | Status | Complexity |
|---------|--------|------------|
| Audio upload (record/upload) | 🔄 Refactor | Medium |
| Cartesia transcription | ✅ Use existing | Low |
| Quote cards (text + visual) | 🆕 New | High |
| Full-text search | 🔄 Simplify | Medium |
| AI semantic search | 🆕 New | High |
| AI memory/family DNA | 🆕 New | Very High |
| Progress tracking (10 stories) | 🔄 Simplify | Low |
| Generic theme + dark/light | 🔄 Simplify | Low |
| Onboarding with prompts | 🆕 New | Medium |

### Technical Decisions
- **Transcription**: Cartesia (existing integration)
- **AI Memory**: OpenAI GPT-4 for pattern analysis + vector embeddings
- **Visual Quote Cards**: Canvas API or pre-designed templates
- **Search**: PostgreSQL full-text search + vector similarity
- **Theme**: Single generic theme with dark/light mode toggle

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Database Schema Changes](#2-database-schema-changes)
3. [Backend Implementation](#3-backend-implementation)
4. [iOS App Implementation](#4-ios-app-implementation)
5. [AI Memory System](#5-ai-memory-system)
6. [Search Implementation](#6-search-implementation)
7. [Quote Card Generation](#7-quote-card-generation)
8. [Onboarding Flow](#8-onboarding-flow)
9. [Week 1 Sprint Timeline](#9-week-1-sprint-timeline)
10. [File Changes Summary](#10-file-changes-summary)

---

## 1. Architecture Overview

### System Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         StoryLane v1 Architecture                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐           │
│  │   iOS App   │────▶│ Cloudflare  │────▶│  Supabase   │           │
│  │  (Upload +  │     │  Workers    │     │  Database   │           │
│  │   Library)  │     │   (Hono)    │     │  (Postgres) │           │
│  └─────────────┘     └──────┬──────┘     └──────┬──────┘           │
│                             │                    │                   │
│                             │                    │                   │
│                             ▼                    ▼                   │
│                       ┌─────────────┐     ┌─────────────┐           │
│                       │     R2      │     │   OpenAI    │           │
│                       │   Bucket    │     │  (GPT-4 +   │           │
│                       │  (Audio)    │     │ Embeddings) │           │
│                       └─────────────┘     └─────────────┘           │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Data Flow (v1)

```
1. User records/uploads audio on iOS
2. Audio uploaded to R2 bucket (key: audio/{user_id}/{timestamp}.{ext})
3. Backend triggers Cartesia transcription
4. Transcript stored in Supabase (responses table)
5. AI extracts 3-5 memorable quotes
6. Visual quote card generated (image overlay)
7. Story card appears in library with quote preview
8. After 10 stories: search unlocks (full-text + semantic)
9. AI analyzes patterns: "Your family bonds through X, Y, Z"
10. Future recommendations based on family DNA
```

### API Endpoints (v1)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/stories/upload` | Upload audio, trigger transcription |
| `GET` | `/api/stories` | List user's stories (library) |
| `GET` | `/api/stories/:id` | Get single story + quotes |
| `GET` | `/api/stories/:id/quote-cards` | Get quote cards for story |
| `GET` | `/api/stories/search?q=...` | Full-text search (unlocks at 10 stories) |
| `POST` | `/api/stories/semantic-search` | AI semantic search |
| `GET` | `/api/user/progress` | Get upload progress (x/10 stories) |
| `GET` | `/api/user/family-dna` | Get AI-analyzed family patterns |
| `GET` | `/api/onboarding/prompts` | Get guided capture prompts |

---

## 2. Database Schema Changes

### New Tables

#### `stories` Table (Modified)

```sql
-- Add new columns to existing stories table
ALTER TABLE stories ADD COLUMN IF NOT EXISTS quote_cards JSONB DEFAULT '[]'::jsonb;
ALTER TABLE stories ADD COLUMN IF NOT EXISTS search_vector tsvector;
ALTER TABLE stories ADD COLUMN IF NOT EXISTS story_summary TEXT;
ALTER TABLE stories ADD COLUMN IF NOT EXISTS emotional_markers JSONB DEFAULT '[]'::jsonb;
ALTER TABLE stories ADD COLUMN IF NOT EXISTS is_searchable BOOLEAN DEFAULT FALSE;
ALTER TABLE stories ADD COLUMN IF NOT EXISTS word_count INTEGER DEFAULT 0;

-- Create full-text search index
CREATE INDEX IF NOT EXISTS idx_stories_search_vector ON stories USING gin(search_vector);

-- Create trigger to auto-update search_vector
CREATE OR REPLACE FUNCTION stories_search_vector_update()
RETURNS TRIGGER AS $$
BEGIN
  NEW.search_vector := 
    setweight(to_tsvector('english', COALESCE(NEW.title, '')), 'A') ||
    setweight(to_tsvector('english', COALESCE(NEW.summary_text, '')), 'B') ||
    setweight(to_tsvector('english', COALESCEIZE(NEW.story_summary, '')), 'C');
  NEW.word_count := COALESCE(array_length(string_to_array(COALESCE(NEW.summary_text, '') || ' ' || COALESCE(NEW.story_summary, ''), ' '), 1), 0);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER stories_search_vector_trigger
  BEFORE INSERT OR UPDATE ON stories
  FOR EACH ROW EXECUTE FUNCTION stories_search_vector_update();
```

#### `quote_cards` Table (New)

```sql
CREATE TABLE IF NOT EXISTS quote_cards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  story_id UUID NOT NULL REFERENCES stories(id) ON DELETE CASCADE,
  quote_text TEXT NOT NULL,
  speaker_name TEXT,
  visual_url TEXT,  -- Generated image URL (stored in R2 or external)
  card_style VARCHAR(50) DEFAULT 'classic',  -- classic, modern, minimal, bold
  is_approved BOOLEAN DEFAULT FALSE,
  share_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_quote_cards_story ON quote_cards(story_id);
CREATE INDEX IF NOT EXISTS idx_quote_cards_visual ON quote_cards(visual_url) WHERE visual_url IS NOT NULL;
```

#### `family_dna` Table (New - For AI Memory)

```sql
CREATE TABLE IF NOT EXISTS family_dna (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE CACHE,
  story_patterns JSONB NOT NULL DEFAULT '[]'::jsonb,  -- Array of detected patterns
  emotional_themes JSONB NOT NULL DEFAULT '[]'::jsonb,  -- Array of themes
  communication_style TEXT,
  bonding_triggers JSONB NOT NULL DEFAULT '[]'::jsonb,  -- What creates meaning
  values_detected JSONB NOT NULL DEFAULT '[]'::jsonb,  -- Family values
  story_archetypes JSONB NOT NULL DEFAULT '[]'::jsonb,  -- Recurring story types
  confidence_scores JSONB NOT NULL DEFAULT '{}'::jsonb,  -- Pattern confidence
  stories_analyzed INTEGER DEFAULT 0,
  last_analyzed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(family_id)
);

CREATE INDEX IF NOT EXISTS idx_family_dna_family ON family_dna(family_id);
```

#### `ai_embeddings` Table (New - For Semantic Search)

```sql
CREATE TABLE IF NOT EXISTS ai_embeddings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  story_id UUID NOT NULL REFERENCES stories(id) ON DELETE CASCADE,
  embedding vector(1536),  -- OpenAI text-embedding-3-small dimensions
  chunk_type VARCHAR(50) DEFAULT 'summary',  -- summary, quote, full_transcript
  chunk_text TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(story_id, chunk_type)
);

CREATE INDEX IF NOT EXISTS idx_ai_embeddings_vector ON ai_embeddings USING ivfflat(embedding vector_cosine_ops);
```

#### `upload_progress` Table (New)

```sql
CREATE TABLE IF NOT EXISTS upload_progress (
  user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  stories_uploaded INTEGER DEFAULT 0,
  last_upload_at TIMESTAMPTZ,
  search_unlocked_at TIMESTAMPTZ,
  onboarding_completed BOOLEAN DEFAULT FALSE,
  guided_prompts_completed JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_upload_progress_user ON upload_progress(user_id);
```

### Modified Tables

#### `responses` Table (Add Transcription Fields)

```sql
-- Add if not exists (Cartesia already handles some)
ALTER TABLE responses ADD COLUMN IF NOT EXISTS cartesian_transcript TEXT;
ALTER TABLE responses ADD COLUMN IF NOT EXISTS transcript_word_count INTEGER;
ALTER TABLE responses ADD COLUMN IF NOT EXISTS emotional_tone VARCHAR(50);
ALTER TABLE responses ADD COLUMN IF NOT EXISTS key_quotes JSONB DEFAULT '[]'::jsonb;
```

---

## 3. Backend Implementation

### Project Structure

```
backend/
├── src/
│   ├── index.ts                    # Main entry (minimal changes)
│   ├── routes/
│   │   ├── stories.ts              # Story CRUD (refactor for v1)
│   │   ├── quotes.ts               # Quote card management (NEW)
│   │   ├── search.ts               # Search endpoints (NEW)
│   │   ├── onboarding.ts           # Onboarding prompts (NEW)
│   │   └── family-dna.ts           # AI memory endpoints (NEW)
│   ├── services/
│   │   ├── transcription.ts        # Cartesia integration
│   │   ├── quote-generator.ts      # Quote extraction + visual cards
│   │   ├── embedding.ts            # OpenAI embeddings for semantic search
│   │   ├── family-dna-analyzer.ts  # AI pattern analysis
│   │   └── search-engine.ts        # Full-text + semantic search
│   ├── utils/
│   │   ├── supabase.ts             # Existing - no changes
│   │   └── config.ts               # Environment config (NEW)
│   └── workers/
│       ├── transcription-worker.ts # Background processing
│       ├── embedding-worker.ts     # Async embedding generation
│       └── dna-analyzer-worker.ts  # Family DNA analysis
```

### Key Files to Create/Modify

#### `backend/src/routes/stories.ts`

```typescript
import { Hono } from 'hono';
import { getSupabase } from '../utils/supabase';
import { processTranscription } from '../services/transcription';
import { generateQuoteCards } from '../services/quote-generator';
import { generateEmbeddings } from '../services/embedding';

type Bindings = {
  SUPABASE_URL: string;
  SUPABASE_KEY: string;
  AUDIO_BUCKET: R2Bucket;
  CARTESIA_API_KEY: string;
  OPENAI_API_KEY: string;
};

const stories = new Hono<{ Bindings: Bindings }>();

// Upload audio story
stories.post('/upload', async (c) => {
  const supabase = getSupabase(c);
  const formData = await c.req.formData();
  
  const audioFile = formData.get('audio') as File;
  const title = formData.get('title') as string || 'Untitled Story';
  const promptId = formData.get('prompt_id') as string | null;
  
  if (!audioFile) {
    return c.json({ error: 'Audio file required' }, 400);
  }

  // Get user from auth
  const { data: { user }, error: authError } = await supabase.auth.getUser();
  if (authError || !user) {
    return c.json({ error: 'Unauthorized' }, 401);
  }

  // Get user profile
  const { data: profile } = await supabase
    .from('profiles')
    .select('id, family_id')
    .eq('auth_user_id', user.id)
    .single();

  if (!profile) {
    return c.json({ error: 'Profile not found' }, 404);
  }

  // Upload to R2
  const audioKey = `audio/${profile.family_id}/${Date.now()}-${audioFile.name}`;
  await c.env.AUDIO_BUCKET.put(audioKey, audioFile);

  // Create story record
  const { data: story, error: storyError } = await supabase
    .from('stories')
    .insert({
      family_id: profile.family_id,
      prompt_id: promptId,
      title,
      is_completed: false,
      is_searchable: false,
    })
    .select()
    .single();

  if (storyError) {
    return c.json({ error: storyError.message }, 500);
  }

  // Create response with audio
  const { data: response, error: responseError } = await supabase
    .from('responses')
    .insert({
      story_id: story.id,
      user_id: profile.id,
      family_id: profile.family_id,
      media_url: audioKey,
      source: 'voice',
    })
    .select()
    .single();

  if (responseError) {
    return c.json({ error: responseError.message }, 500);
  }

  // Trigger async processing
  // In production, use a queue. For v1, we can do this async
  c.executionCtx.waitUntil(
    processTranscription(c.env, supabase, response.id, audioKey)
  );

  return c.json({ 
    success: true, 
    story_id: story.id,
    message: 'Story uploaded! Processing...'
  });
});

// Get story with quotes
stories.get('/:id', async (c) => {
  const supabase = getSupabase(c);
  const storyId = c.req.param('id');

  // Get story
  const { data: story } = await supabase
    .from('stories')
    .select(`
      *,
      responses (
        id,
        transcript,
        media_url,
        user_id,
        profiles (name, avatar_url)
      ),
      quote_cards (
        id,
        quote_text,
        speaker_name,
        visual_url
      )
    `)
    .eq('id', storyId)
    .single();

  if (!story) {
    return c.json({ error: 'Story not found' }, 404);
  }

  return c.json({ story });
});

// Get user library
stories.get('/', async (c) => {
  const supabase = getSupabase(c);
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    return c.json({ error: 'Unauthorized' }, 401);
  }

  const { data: profile } = await supabase
    .from('profiles')
    .select('family_id')
    .eq('auth_user_id', user.id)
    .single();

  const { data: stories } = await supabase
    .from('stories')
    .select(`
      id,
      title,
      created_at,
      quote_cards (quote_text, visual_url),
      voice_count
    `)
    .eq('family_id', profile.family_id)
    .order('created_at', { ascending: false });

  return c.json({ stories: stories || [] });
});

export { stories };
```

#### `backend/src/services/transcription.ts`

```typescript
import type { R2Bucket } from '@cloudflare/workers-types';
import { createClient } from '@supabase/supabase-js';

interface Env {
  CARTESIA_API_KEY: string;
  OPENAI_API_KEY: string;
}

export async function processTranscription(
  env: Env,
  supabase: ReturnType<typeof createClient>,
  responseId: string,
  audioKey: string
) {
  try {
    // Update status to processing
    await supabase
      .from('responses')
      .update({ processing_status: 'processing' })
      .eq('id', responseId);

    // Call Cartesia API for transcription
    const cartesiaResponse = await fetch('https://api.cartesia.ai/tts', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${env.CARTESIA_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'whisper-1',  // Cartesia uses Whisper under the hood
        // You'll need to implement actual Cartesia transcription
        // This is a placeholder - use their actual API
      }),
    });

    // For now, let's use the existing Cartesia integration pattern
    // from backend/src/routes/responses.ts
    const transcript = await cartesiaResponse.text();

    // Update response with transcript
    await supabase
      .from('responses')
      .update({
        transcript,
        cartesian_transcript: transcript,
        processing_status: 'completed',
      })
      .eq('id', responseId);

    // Get story ID
    const { data: response } = await supabase
      .from('responses')
      .select('story_id, transcript')
      .eq('id', responseId)
      .single();

    if (response) {
      // Generate quote cards
      await generateQuoteCards(env, supabase, response.story_id, response.transcript);
      
      // Generate embeddings for semantic search
      await generateEmbeddings(env, supabase, response.story_id, response.transcript);
    }

  } catch (error) {
    console.error('Transcription error:', error);
    await supabase
      .from('responses')
      .update({ processing_status: 'failed' })
      .eq('id', responseId);
  }
}
```

#### `backend/src/services/quote-generator.ts`

```typescript
import OpenAI from 'openai';
import { createClient } from '@supabase/supabase-js';

interface Env {
  OPENAI_API_KEY: string;
  AUDIO_BUCKET: R2Bucket;
}

export async function generateQuoteCards(
  env: Env,
  supabase: ReturnType<typeof createClient>,
  storyId: string,
  transcript: string
) {
  const openai = new OpenAI({ apiKey: env.OPENAI_API_KEY });

  // Use GPT-4 to extract memorable quotes
  const extractionPrompt = `
You are analyzing a family story transcript. Extract 3-5 of the most memorable, quotable moments.

Requirements:
1. Each quote should be 1-2 sentences
2. Include the speaker's name if mentioned in context
3. Focus on wisdom, humor, emotion, or insight
4. Prioritize quotes that would look good on a quote card

Format as JSON array:
[
  {
    "quote": "The actual quote text",
    "speaker": "Speaker name if known"
  }
]

Transcript:
${transcript.substring(0, 8000)}  // Limit to first 8000 chars
`;

  const completion = await openai.chat.completions.create({
    model: 'gpt-4',
    messages: [
      {
        role: 'system',
        content: 'You are an expert at extracting memorable quotes from family stories.'
      },
      {
        role: 'user',
        content: extractionPrompt
      }
    ],
    response_format: { type: 'json_object' },
  });

  const result = JSON.parse(completion.choices[0].message.content || '{"quotes":[]}');
  const quotes = result.quotes || [];

  // Store quotes and generate visual cards
  const quoteCards = [];
  
  for (const quote of quotes) {
    // Generate visual quote card
    const visualUrl = await generateVisualCard(env, quote.quote, quote.speaker);
    
    // Store in database
    const { data: quoteCard } = await supabase
      .from('quote_cards')
      .insert({
        story_id: storyId,
        quote_text: quote.quote,
        speaker_name: quote.speaker,
        visual_url: visualUrl,
      })
      .select()
      .single();
    
    quoteCards.push(quoteCard);
  }

  // Update story with quote cards
  await supabase
    .from('stories')
    .update({
      quote_cards: quoteCards,
      is_searchable: true,
    })
    .eq('id', storyId);

  return quoteCards;
}

async function generateVisualCard(
  env: Env,
  quote: string,
  speaker?: string
): Promise<string | null> {
  // For v1, we'll generate a simple text-based card
  // In production, use a proper image generation service or canvas
  
  // Placeholder: return null for now, implement visual cards in phase 2
  // For v1, we can focus on text quote cards first
  
  return null;  // Will be implemented as visual cards in phase 2
}
```

#### `backend/src/services/embedding.ts`

```typescript
import OpenAI from 'openai';
import { createClient } from '@supabase/supabase-js';

interface Env {
  OPENAI_API_KEY: string;
}

export async function generateEmbeddings(
  env: Env,
  supabase: ReturnType<typeof createClient>,
  storyId: string,
  transcript: string
) {
  const openai = new OpenAI({ apiKey: env.OPENAI_API_KEY });

  // Generate embedding for full transcript
  const embeddingResponse = await openai.embeddings.create({
    model: 'text-embedding-3-small',
    input: transcript.substring(0, 8000),  // Limit length
  });

  const embedding = embeddingResponse.data[0].embedding;

  // Store embedding
  await supabase
    .from('ai_embeddings')
    .upsert({
      story_id: storyId,
      embedding,
      chunk_type: 'full_transcript',
      chunk_text: transcript.substring(0, 1000),
    });

  // Also create a summary embedding
  const summary = await generateSummary(env, transcript);
  
  const summaryEmbedding = await openai.embeddings.create({
    model: 'text-embedding-3-small',
    input: summary,
  });

  await supabase
    .from('ai_embeddings')
    .upsert({
      story_id: storyId,
      embedding: summaryEmbedding.data[0].embedding,
      chunk_type: 'summary',
      chunk_text: summary,
    });

  return true;
}

async function generateSummary(
  env: Env,
  transcript: string
): Promise<string> {
  const openai = new OpenAI({ apiKey: env.OPENAI_API_KEY });

  const completion = await openai.chat.completions.create({
    model: 'gpt-4',
    messages: [
      {
        role: 'system',
        content: 'Summarize this family story in 2-3 sentences.'
      },
      {
        role: 'user',
        content: transcript.substring(0, 8000)
      }
    ],
    max_tokens: 100,
  });

  return completion.choices[0].message.content || '';
}
```

#### `backend/src/routes/search.ts`

```typescript
import { Hono } from 'hono';
import { getSupabase } from '../utils/supabase';
import { semanticSearch } from '../services/search-engine';

type Bindings = {
  SUPABASE_URL: string;
  SUPABASE_KEY: string;
  OPENAI_API_KEY: string;
};

const search = new Hono<{ Bindings: Bindings }>();

// Full-text search
search.get('/stories', async (c) => {
  const supabase = getSupabase(c);
  const query = c.req.query('q');
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    return c.json({ error: 'Unauthorized' }, 401);
  }

  // Get user's family_id
  const { data: profile } = await supabase
    .from('profiles')
    .select('family_id, upload_progress')
    .eq('auth_user_id', user.id)
    .single();

  // Check if search is unlocked
  const progress = profile.upload_progress || {};
  const storiesUploaded = progress.stories_uploaded || 0;

  if (storiesUploaded < 10) {
    return c.json({
      error: 'search_locked',
      message: `Upload ${10 - storiesUploaded} more stories to unlock search`,
      progress: storiesUploaded,
    }, 403);
  }

  // Full-text search
  const { data: stories } = await supabase
    .from('stories')
    .select(`
      id,
      title,
      created_at,
      quote_cards (quote_text),
      voice_count
    `)
    .eq('family_id', profile.family_id)
    .textSearch('search_vector', query)
    .order('created_at', { ascending: false });

  return c.json({ stories: stories || [], type: 'full-text' });
});

// Semantic search
search.post('/stories/semantic', async (c) => {
  const supabase = getSupabase(c);
  const { query } = await c.req.json();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    return c.json({ error: 'Unauthorized' }, 401);
  }

  // Get user's family_id
  const { data: profile } = await supabase
    .from('profiles')
    .select('family_id, upload_progress')
    .eq('auth_user_id', user.id)
    .single();

  // Check if search is unlocked
  const progress = profile.upload_progress || {};
  const storiesUploaded = progress.stories_uploaded || 0;

  if (storiesUploaded < 10) {
    return c.json({
      error: 'search_locked',
      message: `Upload ${10 - storiesUploaded} more stories to unlock search`,
      progress: storiesUploaded,
    }, 403);
  }

  // Semantic search
  const results = await semanticSearch(supabase, profile.family_id, query);

  return c.json({ stories: results, type: 'semantic' });
});

export { search };
```

#### `backend/src/services/family-dna-analyzer.ts`

```typescript
import OpenAI from 'openai';
import { createClient } from '@supabase/supabase-js';

interface Env {
  OPENAI_API_KEY: string;
}

export async function analyzeFamilyDNA(
  env: Env,
  supabase: ReturnType<typeof createClient>,
  familyId: string
) {
  // Get all stories for family
  const { data: stories } = await supabase
    .from('stories')
    .select(`
      id,
      title,
      summary_text,
      quote_cards (quote_text),
      responses (transcript, key_quotes)
    `)
    .eq('family_id', familyId)
    .limit(50);

  if (!stories || stories.length < 5) {
    return null;  // Need at least 5 stories for analysis
  }

  // Prepare data for analysis
  const storyData = stories.map(s => ({
    title: s.title,
    summary: s.summary_text,
    quotes: s.quote_cards?.map(q => q.quote_text).join('\n'),
    transcript: s.responses?.map(r => r.transcript).join('\n').substring(0, 2000),
  }));

  const analysisPrompt = `
You are analyzing family stories to identify patterns. Based on the following family stories, identify:

1. Story archetypes that resonate with this family (adventure, overcoming adversity, humor, love, learning, etc.)
2. Emotional patterns (what emotions appear most in their best stories?)
3. Communication styles (loud/chaotic? quiet/reflective?)
4. Values (what do elders emphasize? What themes repeat?)
5. Traditions and patterns (what activities appear repeatedly?)
6. Bonding triggers (what creates the most meaningful moments?)
7. Humor style (self-deprecating? callbacks? etc.)

Return as JSON:
{
  "story_patterns": ["pattern1", "pattern2"],
  "emotional_themes": ["theme1", "theme2"],
  "communication_style": "description",
  "bonding_triggers": ["trigger1", "trigger2"],
  "values_detected": ["value1", "value2"],
  "story_archetypes": ["archetype1", "archetype2"],
  "confidence_scores": {
    "story_patterns": 0.85,
    "emotional_themes": 0.78,
    "communication_style": 0.65
  }
}

Stories:
${JSON.stringify(storyData, null, 2)}
`;

  const openai = new OpenAI({ apiKey: env.OPENAI_API_KEY });
  
  const completion = await openai.chat.completions.create({
    model: 'gpt-4',
    messages: [
      {
        role: 'system',
        content: 'You are an expert family therapist and story analyst.'
      },
      {
        role: 'user',
        content: analysisPrompt
      }
    ],
    response_format: { type: 'json_object' },
  });

  const analysis = JSON.parse(completion.choices[0].message.content || '{}');

  // Store in family_dna table
  await supabase
    .from('family_dna')
    .upsert({
      family_id: familyId,
      story_patterns: analysis.story_patterns || [],
      emotional_themes: analysis.emotional_themes || [],
      communication_style: analysis.communication_style,
      bonding_triggers: analysis.bonding_triggers || [],
      values_detected: analysis.values_detected || [],
      story_archetypes: analysis.story_archetypes || [],
      confidence_scores: analysis.confidence_scores || {},
      stories_analyzed: stories.length,
      last_analyzed_at: new Date().toISOString(),
    });

  return analysis;
}
```

#### `backend/src/routes/onboarding.ts`

```typescript
import { Hono } from 'hono';
import { getSupabase } from '../utils/supabase';

type Bindings = {
  SUPABASE_URL: string;
  SUPABASE_KEY: string;
};

const onboarding = new Hono<{ Bindings: Bindings }>();

// Guided capture prompts
onboarding.get('/prompts', async (c) => {
  const prompts = [
    {
      id: 'childhood_memory',
      title: 'A Childhood Memory',
      questions: [
        'What was your favorite childhood memory?',
        'Who were your friends growing up?',
        'What was your neighborhood like?'
      ],
      category: 'nostalgia',
    },
    {
      id: 'family_tradition',
      title: 'Family Traditions',
      questions: [
        'What family traditions do you remember from your childhood?',
        'Which tradition was your favorite?',
        'How have traditions changed over the years?'
      ],
      category: 'tradition',
    },
    {
      id: 'life_lesson',
      title: 'Life Lessons',
      questions: [
        'What\'s the most important lesson you\'ve learned?',
        'Would you give the same advice to your younger self?',
        'What do you wish someone had told you earlier?'
      ],
      category: 'wisdom',
    },
    {
      id: 'love_story',
      title: 'Love Stories',
      questions: [
        'How did you meet your partner?',
        'What was your first date like?',
        'What\'s kept you together through the years?'
      ],
      category: 'relationships',
    },
    {
      id: 'career_journey',
      title: 'Career & Work',
      questions: [
        'What was your first job?',
        'What career path led you to where you are?',
        'What\'s the most valuable professional lesson you\'ve learned?'
      ],
      category: 'career',
    },
  ];

  return c.json({ prompts });
});

// Complete prompt and update progress
onboarding.post('/prompt/:id/complete', async (c) => {
  const supabase = getSupabase(c);
  const promptId = c.req.param('id');
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    return c.json({ error: 'Unauthorized' }, 401);
  }

  // Update progress
  const { data: profile } = await supabase
    .from('profiles')
    .select('upload_progress')
    .eq('auth_user_id', user.id)
    .single();

  const progress = profile.upload_progress || {};
  const completedPrompts = progress.guided_prompts_completed || [];
  
  if (!completedPrompts.includes(promptId)) {
    completedPrompts.push(promptId);
  }

  await supabase
    .from('profiles')
    .update({
      upload_progress: {
        ...progress,
        guided_prompts_completed: completedPrompts,
      },
    })
    .eq('auth_user_id', user.id);

  return c.json({ success: true, completed_prompts: completedPrompts });
});

export { onboarding };
```

---

## 4. iOS App Implementation

### New/Modified Files

```
familyplus/familyplus/
├── Views/
│   ├── UploadView.swift           # NEW - Audio upload screen
│   ├── LibraryView.swift          # NEW - Story library
│   ├── StoryCardView.swift        # NEW - Story card component
│   ├── QuoteCardView.swift        # NEW - Quote card display
│   ├── ProgressView.swift         # NEW - Upload progress tracker
│   ├── OnboardingView.swift       # NEW - Onboarding flow
│   ├── PromptCardView.swift       # NEW - Guided prompt display
│   ├── SearchView.swift           # NEW - Search interface
│   └── ThemeToggleView.swift      # NEW - Dark/light toggle
├── Services/
│   ├── StoryService.swift         # NEW - Story API calls
│   ├── SearchService.swift        # NEW - Search API calls
│   ├── QuoteCardService.swift     # NEW - Quote card generation
│   └── FamilyDNAService.swift     # NEW - Family DNA service
├── Models/
│   ├── Story.swift                # Modified - add quote cards
│   ├── QuoteCard.swift            # NEW - Quote card model
│   ├── FamilyDNA.swift            # NEW - Family DNA model
│   ├── UploadProgress.swift       # NEW - Progress model
│   └── Prompt.swift               # NEW - Onboarding prompt model
└── Theme/
    ├── ThemeManager.swift         # MODIFIED - add generic theme
    ├── GenericTheme.swift         # NEW - Generic theme implementation
    └── ThemeToggleManager.swift   # NEW - Dark/light state
```

#### `familyplus/familyplus/Views/UploadView.swift`

```swift
import SwiftUI
import AVFoundation

struct UploadView: View {
  @Environment(\.theme) var theme
  @StateObject private var audioRecorder = AudioRecorderService()
  @StateObject private var storyService = StoryService()
  @State private var isRecording = false
  @State private var recordingDuration: TimeInterval = 0
  @State private var selectedPrompt: Prompt?
  @State private var showingPromptPicker = false
  @State private var isUploading = false
  @State private var uploadProgress: Double = 0
  @State private var showSuccess = false
  
  let prompts: [Prompt] = [
    Prompt(id: "childhood", title: "A Childhood Memory", 
           questions: ["What was your favorite childhood memory?"]),
    Prompt(id: "tradition", title: "Family Traditions",
           questions: ["What family traditions do you remember?"]),
    Prompt(id: "wisdom", title: "Life Lessons",
           questions: ["What's the most important lesson you've learned?"]),
  ]
  
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 24) {
          // Prompt Selection
          PromptSelectionView(
            selectedPrompt: $selectedPrompt,
            showingPicker: $showingPromptPicker,
            prompts: prompts
          )
          
          // Recording Section
          RecordingSection(
            isRecording: $isRecording,
            duration: recordingDuration,
            audioRecorder: audioRecorder,
            onRecordTapped: toggleRecording
          )
          
          // Upload Button
          if audioRecorder.recordedURL != nil {
            UploadButton(
              isUploading: $isUploading,
              progress: $uploadProgress,
              onUpload: uploadStory
            )
          }
          
          // Success State
          if showSuccess {
            SuccessView(onDismiss: { showSuccess = false })
          }
        }
        .padding(theme.screenPadding)
      }
      .navigationTitle("Capture Story")
      .onAppear { startDurationTimer() }
      .onDisappear { stopDurationTimer() }
      .sheet(isPresented: $showingPromptPicker) {
        PromptPickerView(
          prompts: prompts,
          selectedPrompt: $selectedPrompt,
          showingPicker: $showingPromptPicker
        )
      }
    }
  }
  
  private func toggleRecording() {
    if isRecording {
      audioRecorder.stopRecording()
      isRecording = false
    } else {
      do {
        try audioRecorder.startRecording()
        isRecording = true
      } catch {
        print("Failed to start recording: \(error)")
      }
    }
  }
  
  private func uploadStory() {
    guard let audioURL = audioRecorder.recordedURL else { return }
    
    isUploading = true
    uploadProgress = 0
    
    storyService.uploadStory(
      audioURL: audioURL,
      title: selectedPrompt?.title ?? "Untitled Story",
      promptId: selectedPrompt?.id
    ) { result in
      DispatchQueue.main.async {
        isUploading = false
        switch result {
        case .success:
          showSuccess = true
          audioRecorder.clearRecording()
        case .failure(let error):
          print("Upload failed: \(error)")
        }
      }
    }
  }
  
  // Timer for recording duration
  @State private var timer: Timer?
  
  private func startDurationTimer() {
    timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
      if isRecording {
        recordingDuration += 0.1
      }
    }
  }
  
  private func stopDurationTimer() {
    timer?.invalidate()
    timer = nil
  }
}

// MARK: - Subviews

struct PromptSelectionView: View {
  @Environment(\.theme) var theme
  @Binding var selectedPrompt: Prompt?
  @Binding var showingPicker: Bool
  let prompts: [Prompt]
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Choose a prompt")
        .font(theme.headlineFont)
        .foregroundColor(theme.textColor)
      
      Button(action: { showingPicker = true }) {
        HStack {
          if let prompt = selectedPrompt {
            Text(prompt.title)
              .foregroundColor(theme.textColor)
          } else {
            Text("Select a topic to discuss")
              .foregroundColor(theme.secondaryTextColor)
          }
          Spacer()
          Image(systemName: "chevron.down")
            .foregroundColor(theme.secondaryTextColor)
        }
        .padding()
        .background(theme.surfaceColor)
        .cornerRadius(theme.cardRadius)
      }
    }
  }
}

struct PromptPickerView: View {
  let prompts: [Prompt]
  @Binding var selectedPrompt: Prompt?
  @Binding var showingPicker: Bool
  
  var body: some View {
    NavigationStack {
      List(prompts) { prompt in
        Button(action: {
          selectedPrompt = prompt
          showingPicker = false
        }) {
          VStack(alignment: .leading, spacing: 4) {
            Text(prompt.title)
              .font(.headline)
            Text("\(prompt.questions.count) questions")
              .font(.caption)
              .foregroundColor(.secondary)
          }
          .padding(.vertical, 8)
        }
        .foregroundColor(.primary)
      }
      .navigationTitle("Select Prompt")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { showingPicker = false }
        }
      }
    }
  }
}

struct RecordingSection: View {
  @Environment(\.theme) var theme
  @Binding var isRecording: Bool
  let duration: TimeInterval
  let audioRecorder: AudioRecorderService
  let onRecordTapped: () -> Void
  
  var body: some View {
    VStack(spacing: 16) {
      // Duration Display
      Text(formatDuration(duration))
        .font(.system(size: 48, weight: .light, design: .monospaced))
        .foregroundColor(theme.textColor)
      
      // Record Button
      Button(action: onRecordTapped) {
        Circle()
          .fill(isRecording ? theme.alertColor : theme.accentColor)
          .frame(width: 80, height: 80)
          .overlay(
            Image(systemName: isRecording ? "stop.fill" : "mic.fill")
              .font(.system(size: 32))
              .foregroundColor(.white)
          )
          .shadow(color: theme.accentColor.opacity(0.3), radius: 10)
      }
      
      Text(isRecording ? "Tap to stop" : "Tap to record")
        .font(theme.bodyFont)
        .foregroundColor(theme.secondaryTextColor)
    }
  }
  
  private func formatDuration(_ duration: TimeInterval) -> String {
    let minutes = Int(duration) / 60
    let seconds = Int(duration) % 60
    return String(format: "%02d:%02d", minutes, seconds)
  }
}

struct UploadButton: View {
  @Environment(\.theme) var theme
  @Binding var isUploading: Bool
  @Binding var progress: Double
  let onUpload: () -> Void
  
  var body: some View {
    VStack(spacing: 12) {
      Button(action: onUpload) {
        HStack {
          if isUploading {
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle(tint: .white))
            Text("Uploading... \(Int(progress * 100))%")
          } else {
            Image(systemName: "icloud.and.arrow.up")
            Text("Upload Story")
          }
        }
        .font(theme.headlineFont)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding()
        .background(theme.accentColor)
        .cornerRadius(theme.cardRadius)
      }
      .disabled(isUploading)
      
      Text("Your story will be transcribed and processed")
        .font(theme.captionFont)
        .foregroundColor(theme.secondaryTextColor)
    }
  }
}

struct SuccessView: View {
  @Environment(\.theme) var theme
  let onDismiss: () -> Void
  
  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 60))
        .foregroundColor(theme.accentColor)
      
      Text("Story uploaded!")
        .font(theme.headlineFont)
        .foregroundColor(theme.textColor)
      
      Text("Generating quotes and making it searchable...")
        .font(theme.bodyFont)
        .foregroundColor(theme.secondaryTextColor)
        .multilineTextAlignment(.center)
      
      Button(action: onDismiss) {
        Text("Continue")
          .font(theme.headlineFont)
          .foregroundColor(.white)
          .padding(.horizontal, 40)
          .padding(.vertical, 12)
          .background(theme.accentColor)
          .cornerRadius(theme.cardRadius)
      }
    }
    .padding()
    .background(theme.surfaceColor)
    .cornerRadius(theme.cardRadius)
  }
}
```

#### `familyplus/familyplus/Views/LibraryView.swift`

```swift
import SwiftUI

struct LibraryView: View {
  @Environment(\.theme) var theme
  @StateObject private var storyService = StoryService()
  @State private var stories: [Story] = []
  @State private var isLoading = true
  @State private var showingSearch = false
  
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 16) {
          // Progress Header
          ProgressHeaderView()
          
          // Stories Grid
          if isLoading {
            LoadingView()
          } else if stories.isEmpty {
            EmptyLibraryView()
          } else {
            StoriesGridView(stories: stories)
          }
        }
        .padding(theme.screenPadding)
      }
      .navigationTitle("My Stories")
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button(action: { showingSearch = true }) {
            Image(systemName: "magnifyingglass")
              .foregroundColor(theme.textColor)
          }
        }
        
        ToolbarItem(placement: .primaryAction) {
          ThemeToggleButton()
        }
      }
      .task { loadStories() }
      .sheet(isPresented: $showingSearch) {
        SearchView()
      }
    }
  }
  
  private func loadStories() {
    storyService.getStories { result in
      DispatchQueue.main.async {
        isLoading = false
        if case .success(let fetchedStories) = result {
          stories = fetchedStories
        }
      }
    }
  }
}

struct ProgressHeaderView: View {
  @Environment(\.theme) var theme
  @StateObject private var progressService = ProgressService()
  @State private var progress: UploadProgress?
  
  var body: some View {
    VStack(spacing: 12) {
      HStack {
        Text("Your Story Collection")
          .font(theme.headlineFont)
          .foregroundColor(theme.textColor)
        Spacer()
        ThemeToggleButton()
      }
      
      // Progress Bar
      VStack(spacing: 8) {
        ProgressBarView(
          progress: CGFloat((progress?.storiesUploaded ?? 0)) / 10,
          current: progress?.storiesUploaded ?? 0,
          goal: 10
        )
        
        Text(progressMessage)
          .font(theme.captionFont)
          .foregroundColor(theme.secondaryTextColor)
      }
      .padding()
      .background(theme.surfaceColor)
      .cornerRadius(theme.cardRadius)
    }
    .task { loadProgress() }
  }
  
  private var progressMessage: String {
    let uploaded = progress?.storiesUploaded ?? 0
    if uploaded >= 10 {
      return "🎉 Search unlocked! All stories searchable."
    } else {
      return "Upload \(10 - uploaded) more story(stories) to unlock search"
    }
  }
  
  private func loadProgress() {
    progressService.getProgress { result in
      if case .success(let fetchedProgress) = result {
        progress = fetchedProgress
      }
    }
  }
}

struct ProgressBarView: View {
  @Environment(\.theme) var theme
  let progress: CGFloat
  let current: Int
  let goal: Int
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          RoundedRectangle(cornerRadius: 4)
            .fill(theme.secondaryTextColor.opacity(0.2))
            .frame(height: 8)
          
          RoundedRectangle(cornerRadius: 4)
            .fill(theme.accentColor)
            .frame(width: geometry.size.width * min(progress, 1), height: 8)
            .animation(.easeInOut(duration: 0.3), value: progress)
        }
      }
      .frame(height: 8)
      
      HStack {
        Text("\(current)/\(goal) stories")
          .font(theme.captionFont)
          .foregroundColor(theme.secondaryTextColor)
        Spacer()
        if current >= goal {
          Image(systemName: "lock.open.fill")
            .foregroundColor(theme.accentColor)
            .font(theme.captionFont)
        } else {
          Image(systemName: "lock.fill")
            .foregroundColor(theme.secondaryTextColor)
            .font(theme.captionFont)
        }
      }
    }
  }
}

struct StoriesGridView: View {
  @Environment(\.theme) var theme
  let stories: [Story]
  
  let columns = [
    GridItem(.flexible(), spacing: 16),
    GridItem(.flexible(), spacing: 16),
  ]
  
  var body: some View {
    LazyVGrid(columns: columns, spacing: 16) {
      ForEach(stories) { story in
        StoryCardView(story: story)
      }
    }
  }
}

struct EmptyLibraryView: View {
  @Environment(\.theme) var theme
  
  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "book.closed")
        .font(.system(size: 60))
        .foregroundColor(theme.secondaryTextColor)
      
      Text("No stories yet")
        .font(theme.headlineFont)
        .foregroundColor(theme.textColor)
      
      Text("Upload your first story to start building your family's memory collection.")
        .font(theme.bodyFont)
        .foregroundColor(theme.secondaryTextColor)
        .multilineTextAlignment(.center)
    }
    .padding(40)
  }
}

struct LoadingView: View {
  @Environment(\.theme) var theme
  
  var body: some View {
    VStack(spacing: 16) {
      ProgressView()
        .scaleEffect(1.5)
      Text("Loading your stories...")
        .font(theme.bodyFont)
        .foregroundColor(theme.secondaryTextColor)
    }
    .frame(maxWidth: .infinity, minHeight: 300)
  }
}
```

#### `familyplus/familyplus/Views/StoryCardView.swift`

```swift
import SwiftUI

struct StoryCardView: View {
  @Environment(\.theme) var theme
  let story: Story
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Quote Preview
      if let firstQuote = story.quoteCards?.first {
        Text(firstQuote.quoteText)
          .font(theme.bodyFont)
          .foregroundColor(theme.textColor)
          .lineLimit(3)
          .italic()
      }
      
      // Title & Date
      VStack(alignment: .leading, spacing: 4) {
        Text(story.title)
          .font(theme.headlineFont)
          .foregroundColor(theme.textColor)
          .lineLimit(1)
        
        Text(formatDate(story.createdAt))
          .font(theme.captionFont)
          .foregroundColor(theme.secondaryTextColor)
      }
      
      // Stats
      HStack {
        Label("\(story.voiceCount)", systemImage: "person.2.fill")
          .font(theme.captionFont)
          .foregroundColor(theme.secondaryTextColor)
        
        Spacer()
        
        if story.quoteCards?.isEmpty == false {
          Image(systemName: "quote.bubble.fill")
            .foregroundColor(theme.accentColor)
            .font(theme.captionFont)
        }
      }
    }
    .padding()
    .background(theme.surfaceColor)
    .cornerRadius(theme.cardRadius)
    .shadow(color: theme.textColor.opacity(0.1), radius: 4, x: 0, y: 2)
  }
  
  private func formatDate(_ date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter.localizedString(for: date, relativeTo: Date())
  }
}
```

#### `familyplus/familyplus/Theme/GenericTheme.swift`

```swift
import SwiftUI

// Generic Theme for StoryLane v1 (Dark/Light modes only)
struct GenericTheme: PersonaTheme {
  var role: PersonaRole = .generic
  var colorScheme: ColorScheme
  
  // Computed colors based on color scheme
  var backgroundColor: Color {
    colorScheme == .dark ? Color.inkBlack : Color.paperWhite
  }
  
  var textColor: Color {
    colorScheme == .dark ? Color.paperWhite : Color.inkBlack
  }
  
  var secondaryTextColor: Color {
    colorScheme == .dark ? Color.surfaceGrey : Color.darkGrey
  }
  
  var surfaceColor: Color {
    colorScheme == .dark ? Color.darkGrey : Color.surfaceGrey
  }
  
  var accentColor: Color {
    Color.brandIndigo  // Consistent accent across modes
  }
  
  var alertColor: Color {
    Color.alertRed
  }
  
  var successColor: Color {
    Color.storytellerGreen
  }
  
  // Typography
  var headlineFont: Font {
    .title2.weight(.bold)
  }
  
  var bodyFont: Font {
    .body
  }
  
  var captionFont: Font {
    .caption
  }
  
  // Layout
  var screenPadding: CGFloat {
    20
  }
  
  var cardRadius: CGFloat {
    16
  }
  
  var buttonHeight: CGFloat {
    50
  }
  
  // Animation
  var animation: Animation {
    .easeInOut(duration: 0.3)
  }
  
  // Feature flags (all enabled for generic)
  var showNavigation: Bool {
    true
  }
  
  var enableAudioPrompts: Bool {
    true
  }
  
  var enableHaptics: Bool {
    true
  }
}

enum PersonaRole {
  case generic
  case dark
  case light
}

// Theme Manager
class ThemeManager: ObservableObject {
  @Published var colorScheme: ColorScheme = .light
  
  static let shared = ThemeManager()
  
  private init() {
    // Load saved preference
    if let savedScheme = UserDefaults.standard.string(forKey: "colorScheme"),
       let scheme = ColorScheme(rawValue: savedScheme) {
      self.colorScheme = scheme
    }
  }
  
  func toggle() {
    colorScheme = colorScheme == .dark ? .light : .dark
    UserDefaults.standard.set(colorScheme.rawValue, forKey: "colorScheme")
  }
}

// Theme Environment Key
private struct ThemeKey: EnvironmentKey {
  static let defaultValue: GenericTheme = GenericTheme(colorScheme: .light)
}

extension EnvironmentValues {
  var theme: GenericTheme {
    get { self[ThemeKey.self] }
    set { self[ThemeKey.self] = newValue }
  }
}

// View Extension for Theming
extension View {
  func themed(_ colorScheme: ColorScheme) -> some View {
    self.environment(\.theme, GenericTheme(colorScheme: colorScheme))
  }
}

// Theme Toggle Button
struct ThemeToggleButton: View {
  @Environment(\.theme) var theme
  @StateObject private var themeManager = ThemeManager.shared
  
  var body: some View {
    Button(action: { themeManager.toggle() }) {
      Image(systemName: themeManager.colorScheme == .dark ? "sun.max.fill" : "moon.fill")
        .foregroundColor(theme.textColor)
        .font(.system(size: 18))
    }
  }
}
```

#### `familyplus/familyplus/Services/StoryService.swift`

```swift
import Foundation

struct Story: Codable, Identifiable {
  let id: String
  let title: String
  let createdAt: Date
  let voiceCount: Int
  let quoteCards: [QuoteCard]?
  
  enum CodingKeys: String, CodingKey {
    case id
    case title
    case createdAt = "created_at"
    case voiceCount = "voice_count"
    case quoteCards = "quote_cards"
  }
}

struct QuoteCard: Codable, Identifiable {
  let id: String
  let quoteText: String
  let speakerName: String?
  let visualUrl: String?
  
  enum CodingKeys: String, CodingKey {
    case id
    case quoteText = "quote_text"
    case speakerName = "speaker_name"
    case visualUrl = "visual_url"
  }
}

struct StoryUploadResponse: Codable {
  let success: Bool
  let storyId: String
  let message: String
  
  enum CodingKeys: String, CodingKey {
    case success
    case storyId = "story_id"
    case message
  }
}

class StoryService: ObservableObject {
  private let baseURL = "https://your-workers-url.workers.dev"
  private let session: URLSession
  
  init() {
    let config = URLSessionConfiguration.default
    self.session = URLSession(configuration: config)
  }
  
  func uploadStory(
    audioURL: URL,
    title: String,
    promptId: String?,
    completion: @escaping (Result<StoryUploadResponse, Error>) -> Void
  ) {
    var request = URLRequest(url: URL(string: "\(baseURL)/api/stories/upload")!)
    request.httpMethod = "POST"
    
    // Add auth header (implement your auth logic)
    if let token = UserDefaults.standard.string(forKey: "authToken") {
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    
    let boundary = UUID().uuidString
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    
    var body = Data()
    
    // Add audio file
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"recording.m4a\"\r\n".data(using: .utf8)!)
    body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
    body.append(try! Data(contentsOf: audioURL))
    body.append("\r\n".data(using: .utf8)!)
    
    // Add title
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"title\"\r\n\r\n".data(using: .utf8)!)
    body.append("\(title)\r\n".data(using: .utf8)!)
    
    // Add prompt ID if exists
    if let promptId = promptId {
      body.append("--\(boundary)\r\n".data(using: .utf8)!)
      body.append("Content-Disposition: form-data; name=\"prompt_id\"\r\n\r\n".data(using: .utf8)!)
      body.append("\(promptId)\r\n".data(using: .utf8)!)
    }
    
    body.append("--\(boundary)--\r\n".data(using: .utf8)!)
    
    request.httpBody = body
    
    let task = session.dataTask(with: request) { data, response, error in
      if let error = error {
        completion(.failure(error))
        return
      }
      
      guard let data = data else {
        completion(.failure(NSError(domain: "StoryService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
        return
      }
      
      do {
        let response = try JSONDecoder().decode(StoryUploadResponse.self, from: data)
        completion(.success(response))
      } catch {
        completion(.failure(error))
      }
    }
    
    task.resume()
  }
  
  func getStories(completion: @escaping (Result<[Story], Error>) -> Void) {
    var request = URLRequest(url: URL(string: "\(baseURL)/api/stories")!)
    request.httpMethod = "GET"
    
    if let token = UserDefaults.standard.string(forKey: "authToken") {
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    
    let task = session.dataTask(with: request) { data, response, error in
      if let error = error {
        completion(.failure(error))
        return
      }
      
      guard let data = data else {
        completion(.failure(NSError(domain: "StoryService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
        return
      }
      
      struct StoriesResponse: Codable {
        let stories: [Story]
      }
      
      do {
        let response = try JSONDecoder().decode(StoriesResponse.self, from: data)
        completion(.success(response.stories))
      } catch {
        completion(.failure(error))
      }
    }
    
    task.resume()
  }
  
  func getStory(id: String, completion: @escaping (Result<Story, Error>) -> Void) {
    var request = URLRequest(url: URL(string: "\(baseURL)/api/stories/\(id)")!)
    request.httpMethod = "GET"
    
    if let token = UserDefaults.standard.string(forKey: "authToken") {
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    
    let task = session.dataTask(with: request) { data, response, error in
      if let error = error {
        completion(.failure(error))
        return
      }
      
      guard let data = data else {
        completion(.failure(NSError(domain: "StoryService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
        return
      }
      
      struct StoryResponse: Codable {
        let story: Story
      }
      
      do {
        let response = try JSONDecoder().decode(StoryResponse.self, from: data)
        completion(.success(response.story))
      } catch {
        completion(.failure(error))
      }
    }
    
    task.resume()
  }
}
```

#### `familyplus/familyplus/Services/SearchService.swift`

```swift
import Foundation

struct SearchResult: Codable, Identifiable {
  let id: String
  let title: String
  let createdAt: Date
  let quoteText: String?
  let voiceCount: Int
  let type: String
  
  enum CodingKeys: String, CodingKey {
    case id
    case title
    case createdAt = "created_at"
    case quoteText = "quote_text"
    case voiceCount = "voice_count"
    case type
  }
}

struct SearchError: Error {
  let message: String
  let progress: Int?
  let isLocked: Bool
  
  var localizedDescription: String {
    if isLocked {
      return "Upload \(progress ?? 0) more stories to unlock search"
    }
    return message
  }
}

class SearchService: ObservableObject {
  private let baseURL = "https://your-workers-url.workers.dev"
  private let session: URLSession
  
  init() {
    let config = URLSessionConfiguration.default
    self.session = URLSession(configuration: config)
  }
  
  func search(
    query: String,
    completion: @escaping (Result<[SearchResult], Error>) -> Void
  ) {
    var request = URLRequest(url: URL(string: "\(baseURL)/api/search/stories?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)")!)
    request.httpMethod = "GET"
    
    if let token = UserDefaults.standard.string(forKey: "authToken") {
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    
    let task = session.dataTask(with: request) { data, response, error in
      if let error = error {
        completion(.failure(error))
        return
      }
      
      guard let data = data else {
        completion(.failure(NSError(domain: "SearchService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
        return
      }
      
      struct SearchResponse: Codable {
        let stories: [SearchResult]
        let type: String
      }
      
      do {
        let response = try JSONDecoder().decode(SearchResponse.self, from: data)
        completion(.success(response.stories))
      } catch {
        // Check if it's a locked search error
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let errorType = json["error"] as? String,
           errorType == "search_locked" {
          let progress = json["progress"] as? Int
          let message = json["message"] as? String ?? "Search locked"
          completion(.failure(SearchError(message: message, progress: progress, isLocked: true)))
        } else {
          completion(.failure(error))
        }
      }
    }
    
    task.resume()
  }
  
  func semanticSearch(
    query: String,
    completion: @escaping (Result<[SearchResult], Error>) -> Void
  ) {
    var request = URLRequest(url: URL(string: "\(baseURL)/api/search/stories/semantic")!)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    if let token = UserDefaults.standard.string(forKey: "authToken") {
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    
    let body = ["query": query]
    request.httpBody = try! JSONSerialization.data(withJSONObject: body)
    
    let task = session.dataTask(with: request) { data, response, error in
      if let error = error {
        completion(.failure(error))
        return
      }
      
      guard let data = data else {
        completion(.failure(NSError(domain: "SearchService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
        return
      }
      
      struct SearchResponse: Codable {
        let stories: [SearchResult]
        let type: String
      }
      
      do {
        let response = try JSONDecoder().decode(SearchResponse.self, from: data)
        completion(.success(response.stories))
      } catch {
        completion(.failure(error))
      }
    }
    
    task.resume()
  }
}
```

#### `familyplus/familyplus/Views/SearchView.swift`

```swift
import SwiftUI

struct SearchView: View {
  @Environment(\.theme) var theme
  @Environment(\.dismiss) var dismiss
  @StateObject private var searchService = SearchService()
  @State private var query = ""
  @State private var results: [SearchResult] = []
  @State private var isSearching = false
  @State private var error: SearchError?
  @State private var searchType: SearchType = .fullText
  
  enum SearchType: String, CaseIterable {
    case fullText = "Full Text"
    case semantic = "AI Semantic"
  }
  
  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        // Search Bar
        SearchBarView(
          query: $query,
          isSearching: $isSearching,
          searchType: $searchType,
          onSearch: performSearch
        )
        
        // Results or Empty State
        if let error = error {
          SearchLockedView(error: error)
        } else if results.isEmpty && !query.isEmpty && !isSearching {
          EmptySearchView()
        } else if results.isEmpty {
          PlaceholderView()
        } else {
          SearchResultsView(results: results)
        }
      }
      .navigationTitle("Search")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
      }
    }
  }
  
  private func performSearch() {
    guard !query.isEmpty else { return }
    
    isSearching = true
    error = nil
    
    switch searchType {
    case .fullText:
      searchService.search(query: query) { result in
        handleSearchResult(result)
      }
    case .semantic:
      searchService.semanticSearch(query: query) { result in
        handleSearchResult(result)
      }
    }
  }
  
  private func handleSearchResult(_ result: Result<[SearchResult], Error>) {
    DispatchQueue.main.async {
      isSearching = false
      switch result {
      case .success(let searchResults):
        results = searchResults
      case .failure(let searchError):
        if let searchError = searchError as? SearchError {
          error = searchError
        } else {
          print("Search error: \(searchError)")
        }
      }
    }
  }
}

struct SearchBarView: View {
  @Environment(\.theme) var theme
  @Binding var query: String
  @Binding var isSearching: Bool
  @Binding var searchType: SearchView.SearchType
  let onSearch: () -> Void
  
  var body: some View {
    VStack(spacing: 12) {
      HStack {
        HStack {
          Image(systemName: "magnifyingglass")
            .foregroundColor(theme.secondaryTextColor)
          
          TextField("Search stories, quotes, memories...", text: $query)
            .textFieldStyle(.plain)
            .autocorrectionDisabled()
            .onSubmit(onSearch)
          
          if !query.isEmpty {
            Button(action: { query = "" }) {
              Image(systemName: "xmark.circle.fill")
                .foregroundColor(theme.secondaryTextColor)
            }
          }
        }
        .padding(12)
        .background(theme.surfaceColor)
        .cornerRadius(12)
        
        if isSearching {
          ProgressView()
        } else if !query.isEmpty {
          Button("Search") {
            onSearch()
          }
          .font(theme.bodyFont.weight(.semibold))
        }
      }
      
      // Search Type Toggle
      Picker("Search Type", selection: $searchType) {
        ForEach(SearchView.SearchType.allCases, id: \.self) { type in
          Text(type.rawValue).tag(type)
        }
      }
      .pickerStyle(.segmented)
    }
    .padding()
    .background(theme.backgroundColor)
  }
}

struct SearchResultsView: View {
  @Environment(\.theme) var theme
  let results: [SearchResult]
  
  var body: some View {
    ScrollView {
      LazyVStack(spacing: 12) {
        ForEach(results) { result in
          SearchResultCard(result: result)
        }
      }
      .padding()
    }
  }
}

struct SearchResultCard: View {
  @Environment(\.theme) var theme
  let result: SearchResult
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(result.title)
        .font(theme.headlineFont)
        .foregroundColor(theme.textColor)
      
      if let quote = result.quoteText {
        Text("\"\(quote)\"")
          .font(theme.bodyFont.italic())
          .foregroundColor(theme.secondaryTextColor)
          .lineLimit(2)
      }
      
      HStack {
        Label("\(result.voiceCount) voices", systemImage: "person.2.fill")
          .font(theme.captionFont)
          .foregroundColor(theme.secondaryTextColor)
        
        Spacer()
        
        Text(result.type)
          .font(theme.captionFont)
          .foregroundColor(theme.accentColor)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(theme.accentColor.opacity(0.1))
          .cornerRadius(4)
      }
    }
    .padding()
    .background(theme.surfaceColor)
    .cornerRadius(theme.cardRadius)
  }
}

struct SearchLockedView: View {
  @Environment(\.theme) var theme
  let error: SearchError
  
  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "lock.fill")
        .font(.system(size: 50))
        .foregroundColor(theme.secondaryTextColor)
      
      Text("Search Locked")
        .font(theme.headlineFont)
        .foregroundColor(theme.textColor)
      
      Text(error.localizedDescription)
        .font(theme.bodyFont)
        .foregroundColor(theme.secondaryTextColor)
        .multilineTextAlignment(.center)
    }
    .padding(40)
  }
}

struct EmptySearchView: View {
  @Environment(\.theme) var theme
  
  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 50))
        .foregroundColor(theme.secondaryTextColor)
      
      Text("No results found")
        .font(theme.headlineFont)
        .foregroundColor(theme.textColor)
      
      Text("Try different keywords or add more stories")
        .font(theme.bodyFont)
        .foregroundColor(theme.secondaryTextColor)
    }
    .padding(40)
  }
}

struct PlaceholderView: View {
  @Environment(\.theme) var theme
  
  var body: some View {
    VStack(spacing: 12) {
      Image(systemName: "text.magnifyingglass")
        .font(.system(size: 40))
        .foregroundColor(theme.secondaryTextColor.opacity(0.5))
      
      Text("Search your stories")
        .font(theme.headlineFont)
        .foregroundColor(theme.secondaryTextColor)
      
      Text("Find quotes, memories, and conversations")
        .font(theme.bodyFont)
        .foregroundColor(theme.secondaryTextColor.opacity(0.7))
    }
    .padding(40)
  }
}
```

---

## 5. AI Memory System

### Overview

The AI Memory System ("Family DNA") analyzes uploaded stories to identify patterns and preferences unique to each family. This enables personalized experience recommendations in future versions.

### Components

1. **Pattern Detection** - Analyzes stories for recurring themes
2. **Emotional Mapping** - Identifies emotional triggers and responses
3. **Value Extraction** - Extracts family values and priorities
4. **Recommendation Engine** - Suggests future experiences based on patterns

### Implementation Flow

```
Upload Story → Transcription → Pattern Analysis → Update Family DNA → Store in Database
                                                                          ↓
                                                              User Queries Family DNA
```

### API Endpoints

```typescript
// Get Family DNA
GET /api/family-dna
Response: {
  "family_id": "uuid",
  "story_patterns": ["chaos_resolution", "multi_gen", "cooking"],
  "emotional_themes": ["nostalgia", "humor", "triumph"],
  "communication_style": "loud_and_chaotic",
  "bonding_triggers": ["shared_activities", "storytelling"],
  "values_detected": ["family_togetherness", "resilience"],
  "story_archetypes": ["underdog", "coming_of_age"],
  "confidence_scores": {
    "story_patterns": 0.85,
    "emotional_themes": 0.78
  },
  "stories_analyzed": 12
}

// Trigger DNA Analysis
POST /api/family-dna/analyze
Response: { "status": "analyzing" }
```

### Analysis Triggers

- Automatic: After every 5 new stories
- Manual: User triggers from settings
- On-demand: When family first reaches 10 stories

### Family DNA Display (Future UI)

```
┌─────────────────────────────────────────┐
│     Your Family's Story DNA              │
├─────────────────────────────────────────┤
│                                          │
│  🎯 What Makes Your Stories Special     │
│  ─────────────────────────────────────  │
│  • Multi-generational participation     │
│  • Mild chaos that gets resolved        │
│  • Cooking/food involved                │
│                                          │
│  💝 Emotional Patterns                   │
│  ─────────────────────────────────────  │
│  • Humor through self-deprecation       │
│  • Nostalgia for childhood              │
│  • Triumph over adversity               │
│                                          │
│  🔥 Bonding Triggers                     │
│  ─────────────────────────────────────  │
│  • Shared activities                    │
│  • Learning moments                     │
│  • Physical activity + conversation     │
│                                          │
│  📊 Confidence: 85%                      │
│  📚 Stories Analyzed: 12                 │
│                                          │
└─────────────────────────────────────────┘
```

---

## 6. Search Implementation

### Full-Text Search

Uses PostgreSQL's built-in full-text search with weighted vectors:

```sql
-- Search query
SELECT id, title, ts_headline('english', summary_text, plainto_tsquery('english', $query)) as highlighted
FROM stories
WHERE family_id = $family_id
  AND search_vector @@ plainto_tsquery('english', $query)
ORDER BY ts_rank(search_vector, plainto_tsquery('english', $query)) DESC;
```

### Semantic Search

Uses OpenAI embeddings with PostgreSQL vector similarity:

```typescript
// Semantic search implementation
async function semanticSearch(supabase, familyId, query) {
  // Generate embedding for query
  const embeddingResponse = await openai.embeddings.create({
    model: 'text-embedding-3-small',
    input: query,
  });
  
  const queryEmbedding = embeddingResponse.data[0].embedding;
  
  // Find similar stories
  const { data: stories } = await supabase
    .rpc('match_stories', {
      query_embedding: queryEmbedding,
      match_threshold: 0.7,
      match_count: 10,
      family_id: familyId,
    });
  
  return stories;
}
```

### Search Unlock Mechanism

```typescript
// Check upload count before allowing search
async function canSearch(supabase, userId) {
  const { data: progress } = await supabase
    .from('upload_progress')
    .select('stories_uploaded')
    .eq('user_id', userId)
    .single();
  
  return (progress?.stories_uploaded || 0) >= 10;
}
```

### Search UI States

```
State 1: Before 10 Stories
┌─────────────────────────────────────┐
│  🔍 Search                          │
│  ────────────────────────────────   │
│                                     │
│     🔒 Search Locked                │
│                                     │
│  Upload 7 more stories to unlock    │
│  full-text and semantic search.     │
│                                     │
└─────────────────────────────────────┘

State 2: After 10 Stories
┌─────────────────────────────────────┐
│  🔍 Search                          │
│  ────────────────────────────────   │
│  [ Full Text | AI Semantic ]        │
│                                     │
│  [____________________] 🔍          │
│                                     │
│  Results appear here...             │
│                                     │
└─────────────────────────────────────┘
```

---

## 7. Quote Card Generation

### Text Quote Cards

Generated via GPT-4 extraction from transcripts:

```typescript
const quoteExtractionPrompt = `
Extract the most memorable, quotable moments from this family story.
Focus on:
- Wisdom and life lessons
- Humor and funny moments
- Emotional highlights
- Memorable phrases

Format as JSON array of objects with "quote" and "speaker" fields.
Limit to 3-5 quotes per story.
`;
```

### Visual Quote Cards (Phase 2)

For v1, we'll focus on text quote cards. Visual cards can be added in phase 2 with:

- **Option A**: DALL-E image generation with text overlay
- **Option B**: Pre-designed templates with canvas rendering
- **Option C**: User-selected background images

### Quote Card Data Structure

```typescript
interface QuoteCard {
  id: string;
  storyId: string;
  quoteText: string;
  speakerName?: string;
  visualUrl?: string;  // Phase 2
  cardStyle: 'classic' | 'modern' | 'minimal' | 'bold';
  isApproved: boolean;
  shareCount: number;
  createdAt: Date;
}
```

### Quote Card Display

```
┌─────────────────────────────────────────┐
│                                         │
│   "And that's when I realized           │
│    the real treasure wasn't the gold,   │
│    but the journey we took together."   │
│                                         │
│              — Grandpa Joe              │
│                                         │
│   📤 Share    ❤️ Save    💾 Export      │
│                                         │
└─────────────────────────────────────────┘
```

---

## 8. Onboarding Flow

### Step 1: Welcome Screen

```
┌─────────────────────────────────────────┐
│                                         │
│          📖 StoryLane                   │
│                                         │
│   "Most families accidentally           │
│    stumble into their best memories.    │
│    We help you create experiences       │
│    that become the stories              │
│    you'll tell forever."                │
│                                         │
│         [Get Started] →                 │
│                                         │
└─────────────────────────────────────────┘
```

### Step 2: Choose Your First Story

```
┌─────────────────────────────────────────┐
│                                         │
│   Let's capture your first story!       │
│                                         │
│   Choose a topic:                       │
│   ┌─────────────────────────────────┐   │
│   │ 🏠 A Childhood Memory           │   │
│   │ "What was your favorite         │   │
│   │  childhood memory?"             │   │
│   └─────────────────────────────────┘   │
│   ┌─────────────────────────────────┐   │
│   │ 💕 How We Met                   │   │
│   │ "How did you meet your          │   │
│   │  partner?"                      │   │
│   └─────────────────────────────────┘   │
│   ┌─────────────────────────────────┐   │
│   │ 🎓 Life Lessons                 │   │
│   │ "What's the most important      │   │
│   │  lesson you've learned?"        │   │
│   └─────────────────────────────────┘   │
│   ┌─────────────────────────────────┐   │
│   │ 📸 A Family Tradition           │   │
│   │ "What traditions do you         │   │
│   │  remember?"                     │   │
│   └─────────────────────────────────┘   │
│                                         │
│         [Or, upload existing]           │
│                                         │
└─────────────────────────────────────────┘
```

### Step 3: Record Story

```
┌─────────────────────────────────────────┐
│                                         │
│   🏠 A Childhood Memory                 │
│                                         │
│   Questions to guide you:               │
│   • What was your favorite memory?      │
│   • Who were your friends?              │
│   • What was your neighborhood like?    │
│                                         │
│   ─────────────────────────────────     │
│                                         │
│           ⏱ 00:00                       │
│                                         │
│           ●─────────────────────        │
│           | Record / Stop               │
│                                         │
│     Tap to record, tap to stop          │
│                                         │
└─────────────────────────────────────────┘
```

### Step 4: Processing Animation

```
┌─────────────────────────────────────────┐
│                                         │
│   📤 Uploading...                       │
│                                         │
│   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  67%   │
│                                         │
│   Processing your story...              │
│                                         │
│   ✨ Transcribing audio                 │
│   📝 Extracting memorable quotes        │
│   🔍 Making searchable                  │
│   🎨 Generating quote cards             │
│                                         │
│         [Continue in background]        │
│                                         │
└─────────────────────────────────────────┘
```

### Step 5: Success + Next Steps

```
┌─────────────────────────────────────────┐
│                                         │
│   ✅ Story captured!                    │
│                                         │
│   "And that's when I realized           │
│    the real treasure wasn't the gold,   │
│    but the journey..."                  │
│                                         │
│              — Grandpa Joe              │
│                                         │
│   ─────────────────────────────────     │
│                                         │
│   📊 Progress: 1/10 stories             │
│   🔒 Search: Locked (9 more to go)      │
│                                         │
│         [Capture Another Story]         │
│                                         │
│   or                                   │
│         [Browse Library]                │
│                                         │
└─────────────────────────────────────────┘
```

---

## 9. Week 1 Sprint Timeline

### Day 1: Database & Backend Foundation
- [ ] Create database migration script
- [ ] Set up new tables (quote_cards, family_dna, ai_embeddings, upload_progress)
- [ ] Modify stories table (add columns, indexes, triggers)
- [ ] Test database changes locally

### Day 2: Backend Services
- [ ] Implement quote extraction service
- [ ] Implement embedding generation service
- [ ] Implement search endpoints (full-text + semantic)
- [ ] Implement family DNA analysis service
- [ ] Implement onboarding prompts endpoint

### Day 3: Backend Routes
- [ ] Refactor stories/upload endpoint
- [ ] Create search routes
- [ ] Create family-dna routes
- [ ] Create onboarding routes
- [ ] Test all endpoints with Postman/curl

### Day 4: iOS Upload & Library
- [ ] Create UploadView with guided prompts
- [ ] Create LibraryView with story cards
- [ ] Implement StoryService API calls
- [ ] Create progress tracking UI
- [ ] Connect to backend API

### Day 5: iOS Search & Theme
- [ ] Create SearchView with full-text + semantic toggle
- [ ] Implement SearchService API calls
- [ ] Create generic theme with dark/light modes
- [ ] Implement ThemeManager
- [ ] Test all iOS features

### Day 6: Integration & Testing
- [ ] End-to-end testing (upload → transcribe → quote → search)
- [ ] Test with 10+ stories to unlock search
- [ ] Performance testing
- [ ] Bug fixes and edge cases
- [ ] Code review

### Day 7: Deployment & Launch
- [ ] Deploy backend to Cloudflare Workers
- [ ] Deploy database changes to Supabase
- [ ] Submit iOS build to TestFlight (optional)
- [ ] Documentation
- [ ] Launch! 🎉

---

## 10. File Changes Summary

### New Files to Create

#### Backend
```
backend/src/routes/search.ts
backend/src/routes/onboarding.ts
backend/src/routes/family-dna.ts
backend/src/services/quote-generator.ts
backend/src/services/embedding.ts
backend/src/services/family-dna-analyzer.ts
backend/src/services/search-engine.ts
backend/src/workers/embedding-worker.ts
backend/src/workers/dna-analyzer-worker.ts
```

#### iOS
```
familyplus/familyplus/Views/UploadView.swift
familyplus/familyplus/Views/LibraryView.swift
familyplus/familyplus/Views/StoryCardView.swift
familyplus/familyplus/Views/QuoteCardView.swift
familyplus/familyplus/Views/ProgressView.swift
familyplus/familyplus/Views/OnboardingView.swift
familyplus/familyplus/Views/PromptCardView.swift
familyplus/familyplus/Views/SearchView.swift
familyplus/familyplus/Views/ThemeToggleView.swift
familyplus/familyplus/Services/StoryService.swift
familyplus/familyplus/Services/SearchService.swift
familyplus/familyplus/Services/QuoteCardService.swift
familyplus/familyplus/Services/FamilyDNAService.swift
familyplus/familyplus/Services/ProgressService.swift
familyplus/familyplus/Models/Story.swift
familyplus/familyplus/Models/QuoteCard.swift
familyplus/familyplus/Models/FamilyDNA.swift
familyplus/familyplus/Models/UploadProgress.swift
familyplus/familyplus/Models/Prompt.swift
familyplus/familyplus/Theme/GenericTheme.swift
familyplus/familyplus/Theme/ThemeManager.swift
```

### Files to Modify

#### Backend
```
backend/src/routes/stories.ts        # Add upload endpoint, simplify
backend/src/routes/responses.ts      # Keep transcription, refactor if needed
backend/src/index.ts                 # Add new routes
backend/src/utils/supabase.ts        # No changes needed
```

#### iOS
```
familyplus/familyplus/familyplusApp.swift      # Update theme setup
familyplus/familyplus/MainAppView.swift        # Update navigation
familyplus/familyplus/Theme/PersonaTheme.swift # Simplify for v1
familyplus/familyplus/Components/CaptureMemorySheet.swift  # Can be reused/deprecated
```

### Database Migrations
```
supabase/migrations/
├── 20260108000000_storylane_v1_schema.sql    # New tables
└── 20260108000001_storylane_v1_alterations.sql  # Table modifications
```

---

## Appendix A: Environment Variables

### Backend (.dev.vars)

```bash
# Existing
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-anon-key
AUDIO_BUCKET=your-r2-bucket-name
CARTESIA_API_KEY=your-cartesia-key

# New for v1
OPENAI_API_KEY=your-openai-key
```

### Wrangler Secrets

```bash
wrangler secret put OPENAI_API_KEY
```

---

## Appendix B: API Reference

### Stories API

#### POST /api/stories/upload
Upload a new audio story.

**Request**: Multipart form data
- `audio`: Audio file (m4a, mp3, wav)
- `title`: Story title (optional)
- `prompt_id`: Associated prompt ID (optional)

**Response**:
```json
{
  "success": true,
  "story_id": "uuid",
  "message": "Story uploaded! Processing..."
}
```

#### GET /api/stories
List all stories for user's family.

**Response**:
```json
{
  "stories": [
    {
      "id": "uuid",
      "title": "Story Title",
      "created_at": "2026-01-08T10:00:00Z",
      "voice_count": 2,
      "quote_cards": [
        {
          "id": "uuid",
          "quote_text": "Memorable quote...",
          "speaker_name": "Grandpa Joe",
          "visual_url": null
        }
      ]
    }
  ]
}
```

### Search API

#### GET /api/search/stories?q=query
Full-text search (requires 10+ stories).

**Response**:
```json
{
  "stories": [...],
  "type": "full-text"
}
```

**Error (search locked)**:
```json
{
  "error": "search_locked",
  "message": "Upload 7 more stories to unlock search",
  "progress": 3
}
```

#### POST /api/search/stories/semantic
AI semantic search (requires 10+ stories).

**Request**:
```json
{
  "query": "What advice did grandpa give about money?"
}
```

### Onboarding API

#### GET /api/onboarding/prompts
Get guided capture prompts.

**Response**:
```json
{
  "prompts": [
    {
      "id": "childhood_memory",
      "title": "A Childhood Memory",
      "questions": [
        "What was your favorite childhood memory?",
        "Who were your friends growing up?"
      ],
      "category": "nostalgia"
    }
  ]
}
```

### Family DNA API

#### GET /api/family-dna
Get analyzed family patterns.

**Response**:
```json
{
  "family_id": "uuid",
  "story_patterns": ["multi_gen", "chaos_resolution"],
  "emotional_themes": ["humor", "nostalgia"],
  "communication_style": "loud_and_chaotic",
  "bonding_triggers": ["shared_activities", "learning"],
  "values_detected": ["family_togetherness"],
  "story_archetypes": ["coming_of_age"],
  "confidence_scores": {
    "story_patterns": 0.85
  },
  "stories_analyzed": 12
}
```

---

## Appendix C: Success Metrics

### Day 1 Success Criteria
- [ ] Database migration runs successfully
- [ ] New tables created with proper indexes
- [ ] All RLS policies tested

### Day 2 Success Criteria
- [ ] Quote extraction working on test transcripts
- [ ] Embeddings generated and stored
- [ ] Full-text search returning results
- [ ] Semantic search returning results

### Day 3 Success Criteria
- [ ] All API endpoints responding
- [ ] Authentication working
- [ ] Error handling in place

### Day 4 Success Criteria
- [ ] Audio upload working from iOS
- [ ] Story cards displaying correctly
- [ ] Progress tracking updating

### Day 5 Success Criteria
- [ ] Search functionality working
- [ ] Dark/light theme toggling
- [ ] All screens navigate correctly

### Day 6 Success Criteria
- [ ] Complete end-to-end flow tested
- [ ] 10 stories uploaded and search unlocked
- [ ] No critical bugs

### Day 7 Success Criteria
- [ ] Backend deployed to production
- [ ] Database updated in production
- [ ] iOS build ready for TestFlight (optional)
- [ ] Documentation complete

---

**Document Version**: 1.0  
**Last Updated**: January 8, 2026  
**Author**: StoryLane Engineering Team  
