// ============================================================================
// CLOUDFLARE WORKER ENTRY POINT
// ============================================================================
//
// This file exports:
// 1. HTTP API server (Hono app)
// 2. Queue consumer (Background event processor)
//
// The worker handles both incoming HTTP requests AND background event processing.
// ============================================================================

import { Hono } from 'hono'
import { cors } from 'hono/cors'
import stories from './routes/stories'
import responses from './routes/responses'
import profiles from './routes/profiles'
import families from './routes/families'
import reactions from './routes/reactions'
import quotes from './routes/quotes'
import links from './routes/links'
import polls from './routes/polls'
import analytics from './routes/analytics'
import trivia from './routes/trivia'
import locations from './routes/locations'
import ai from './routes/ai'
import wisdom from './routes/wisdom'
import diary from './routes/diary'
import share from './routes/share'
import exportRoutes from './routes/export'
import settings from './routes/settings'
import { createQwenTurboClient } from './ai/llm'
import { createCartesiaClient } from './ai/cartesia'
import { getSupabaseFromContext, getSupabaseFromEnv } from './utils/supabase'

// ----------------------------------------------------------------------------
// TYPES & BINDINGS
// ----------------------------------------------------------------------------

type Bindings = {
  SUPABASE_URL: string
  SUPABASE_KEY: string
  AUDIO_BUCKET: R2Bucket
  OPENAI_API_KEY: string
  AWS_BEARER_TOKEN_BEDROCK: string
  BEDROCK_REGION: string
  // Twilio for elder notifications
  TWILIO_ACCOUNT_SID: string
  TWILIO_AUTH_TOKEN: string
  TWILIO_PHONE_NUMBER: string
  // Cartesia (Transcription)
  CARTESIA_API_KEY: string
  // Event queue (Cloudflare Queue)
  QUEUE: Queue<any>
}

type Env = Bindings

// ----------------------------------------------------------------------------
// HTTP APP SETUP
// ----------------------------------------------------------------------------

const app = new Hono<{ Bindings: Bindings }>()

app.use('*', cors({
  origin: '*',
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization'],
}))

app.use('*', async (c, next) => {
  // Initialize Supabase client
  const supabase = getSupabaseFromContext(c)
  c.set('supabase', supabase as unknown as any)

  await next()
})

// Mount routes
app.route('/', stories)
app.route('/', responses)
app.route('/', profiles)
app.route('/', families)
app.route('/', reactions)
app.route('/', quotes)
app.route('/', links)
app.route('/', polls)
app.route('/', analytics)
app.route('/', trivia)
app.route('/', locations)
app.route('/', ai)
app.route('/', wisdom)
app.route('/', diary)
app.route('/', share)
app.route('/', exportRoutes)
app.route('/', settings)

// Health check
app.get('/health', (c) => {
  return c.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    mode: 'http+queue',
  })
})

// ----------------------------------------------------------------------------
// QUEUE CONSUMER - Event handler
// ----------------------------------------------------------------------------

export default {
  // HTTP fetch handler
  fetch: app.fetch,

  // Queue message handler
  queue: async (batch: MessageBatch<any>, env: Env, ctx: ExecutionContext): Promise<void> => {
    // Initialize services
    const supabase = getSupabaseFromEnv()

    const llm = createQwenTurboClient({
      openaiApiKey: env.AWS_BEARER_TOKEN_BEDROCK || env.OPENAI_API_KEY,
    })

    const cartesia = createCartesiaClient({
      apiKey: env.CARTESIA_API_KEY,
    })

    // Get handler context
    const handlerContext = {
      supabase,
      llm,
      cartesia,
      env,
    }

    // Process batch
    await handleQueueBatch(batch, handlerContext)
  },
}
