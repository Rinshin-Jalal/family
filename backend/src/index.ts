// ============================================================================
// CLOUDFLARE WORKER ENTRY POINT
// ============================================================================
//
// This file exports both:
// 1. HTTP API server (Hono app)
// 2. Queue consumer (Background event processor)
//
// The worker handles both incoming HTTP requests AND background event processing.
// ============================================================================

import { Hono } from 'hono'
import { cors } from 'hono/cors'
import { createClient } from '@supabase/supabase-js'
import stories from './routes/stories'
import prompts from './routes/prompts'
import responses from './routes/responses'
import profiles from './routes/profiles'
import reactions from './routes/reactions'
import ai from './routes/ai'
import { createQwenTurboClient } from './ai/llm'
import { createCartesiaClient } from './ai/cartesia'
import { handleQueueBatch, type HandlerContext } from './events/handlers'

// ----------------------------------------------------------------------------
// TYPES & BINDINGS
// ----------------------------------------------------------------------------

type Bindings = {
  SUPABASE_URL: string
  SUPABASE_KEY: string
  AUDIO_BUCKET: R2Bucket
  OPENAI_API_KEY: string
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

// Middleware: Initialize services and attach to context
app.use('*', async (c, next) => {
  // Initialize Supabase client
  const supabase = createClient(
    c.env.SUPABASE_URL,
    c.env.SUPABASE_KEY,
    {
      auth: { persistSession: false },
    }
  )
  c.set('supabase', supabase)

  // Make queue available to routes
  c.set('queue', c.env.QUEUE)

  await next()
})

// Mount routes
app.route('/', stories)
app.route('/', prompts)
app.route('/', responses)
app.route('/', profiles)
app.route('/', reactions)
app.route('/', ai)

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

/**
 * This function is called by Cloudflare when messages are available in the queue.
 *
 * It processes batches of events in parallel, routing each to the appropriate handler.
 */
export default {
  // HTTP fetch handler
  fetch: app.fetch,

  // Queue message handler
  queue: async (batch: MessageBatch<any>, env: Env, ctx: ExecutionContext): Promise<void> => {
    // Initialize services
    const supabase = createClient(env.SUPABASE_URL, env.SUPABASE_KEY, {
      auth: { persistSession: false },
    })

    const llm = createQwenTurboClient({
      openaiApiKey: env.OPENAI_API_KEY,
    })

    const cartesia = createCartesiaClient({
      apiKey: env.CARTESIA_API_KEY,
    })

    // Build handler context
    const handlerContext: HandlerContext = {
      supabase,
      llm,
      cartesia,
      env,
    }

    // Process the batch
    await handleQueueBatch(batch, handlerContext)
  },
}
