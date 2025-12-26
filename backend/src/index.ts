import { Hono } from 'hono'
import { createClient } from '@supabase/supabase-js'

type Bindings = {
  SUPABASE_URL: string
  SUPABASE_KEY: string
  AUDIO_BUCKET: R2Bucket
  twilio_account_sid: string
  twilio_auth_token: string
}

const app = new Hono<{ Bindings: Bindings }>()

const getSupabase = (c: any) => {
  return createClient(c.env.SUPABASE_URL, c.env.SUPABASE_KEY)
}

app.get('/', (c) => c.text('Hello World'))

export default {
  fetch: app.fetch,
}
