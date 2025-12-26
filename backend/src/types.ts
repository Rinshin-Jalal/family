interface Story {
  id: string
  prompt_id: string
  family_id: string
  title?: string
  summary_text?: string
  cover_image_url?: string
  voice_count: number
  is_completed: boolean
  created_at: string
}

interface Response {
  id: string
  prompt_id: string
  story_id: string
  user_id: string
  source: 'phone_ai' | 'app_audio' | 'app_text'
  media_url?: string
  transcription_text?: string
  duration_seconds?: number
  processing_status: 'pending' | 'completed' | 'failed'
  reply_to_response_id?: string
  created_at: string
}

interface Profile {
  id: string
  auth_user_id?: string
  family_id: string
  full_name?: string
  avatar_url?: string
  role: 'organizer' | 'elder' | 'member' | 'child'
  phone_number?: string
  created_at: string
}

export type { Story, Response, Profile }

