import { Hono } from 'hono'
import { cors } from 'hono/cors'
import stories from './routes/stories'
import prompts from './routes/prompts'
import responses from './routes/responses'
import profiles from './routes/profiles'
import reactions from './routes/reactions'
import ai from './routes/ai'

type Bindings = {
  SUPABASE_URL: string
  SUPABASE_KEY: string
  AUDIO_BUCKET: R2Bucket
  OPENAI_API_KEY: string
}

const app = new Hono<{ Bindings: Bindings }>()

app.use('*', cors({
  origin: '*',
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization'],
}))

app.route('/', stories)
app.route('/', prompts)
app.route('/', responses)
app.route('/', profiles)
app.route('/', reactions)
app.route('/', ai)

app.get('/health', (c) => {
  return c.json({ status: 'ok', timestamp: new Date().toISOString() })
})

export default {
  fetch: app.fetch,
}
