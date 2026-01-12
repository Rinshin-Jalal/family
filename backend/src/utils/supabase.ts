// ============================================================================
// SUPABASE FACTORY
// ============================================================================
//
// Centralized factory for creating Supabase clients across the application.
// Ensures consistent configuration and easy testing.
//
// USAGE:
// - HTTP routes: getSupabaseFromContext(c)
// - Background jobs: getSupabaseFromEnv()
// - Tests: createSupabaseClient(config)
//
// ============================================================================

import { createClient } from '@supabase/supabase-js'

// ============================================================================
// TYPES
// ============================================================================

export interface SupabaseConfig {
  url: string
  key: string
  options?: {
    auth?: {
      persistSession?: boolean
      autoRefreshToken?: boolean
      detectSessionInUrl?: boolean
    }
  }
}

export interface HonoContext {
  env: {
    SUPABASE_URL: string
    SUPABASE_KEY: string
  }
  set: (key: string, value: unknown) => void
  get: (key: string) => unknown
}

// ============================================================================
// FACTORY FUNCTIONS
// ============================================================================

/**
 * Create Supabase client from Hono context (for HTTP routes)
 *
 * Automatically reads from c.env.SUPABASE_URL and c.env.SUPABASE_KEY
 * Disables session persistence (we use JWT tokens instead)
 */
export function getSupabaseFromContext(c: HonoContext) {
  return createClient(
    c.env.SUPABASE_URL,
    c.env.SUPABASE_KEY,
    {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
        detectSessionInUrl: false,
      },
    }
  )
}
  )

  if (authToken) {
    client.auth.setSession({
      access_token: authToken,
      refresh_token: '',
      expires_in: 3600,
      expires_at: Math.floor(Date.now() / 1000) + 3600,
      token_type: 'bearer',
      user: null as any,
    })
  }

  return client
}

/**
 * Create Supabase client from environment variables (for background jobs)
 *
 * Reads from process.env.SUPABASE_URL and process.env.SUPABASE_KEY
 * Same config as HTTP version for consistency
 */
export function getSupabaseFromEnv() {
  const url = process.env.SUPABASE_URL
  const key = process.env.SUPABASE_KEY

  if (!url || !key) {
    throw new Error('SUPABASE_URL and SUPABASE_KEY must be set in environment')
  }

  return createClient(url, key, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
      detectSessionInUrl: false,
    },
  })
}

/**
 * Create Supabase client from explicit config (for testing)
 *
 * Useful for unit tests with mock Supabase
 */
export function createSupabaseClient(config: SupabaseConfig) {
  return createClient(config.url, config.key, config.options)
}

// ============================================================================
// DEFAULT CONFIG (for convenience)
// ============================================================================

/**
 * Standard Supabase options used across the application
 */
export const DEFAULT_SUPABASE_OPTIONS = {
  auth: {
    persistSession: false,
    autoRefreshToken: false,
    detectSessionInUrl: false,
  },
}
