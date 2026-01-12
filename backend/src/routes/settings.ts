//
//  User Settings Routes
//  API endpoints for managing user notification, privacy, and preference settings
//

import { Hono } from 'hono'
import { authMiddleware } from '../middleware/auth'

const settings = new Hono()

// Type definitions
interface UserSettings {
    id: string
    user_id: string
    push_enabled: boolean
    email_enabled: boolean
    share_with_family: boolean
    allow_suggestions: boolean
    data_retention: '3_months' | '6_months' | '1_year' | 'forever'
    created_at: string
    updated_at: string
}

interface UpdateSettingsRequest {
    push_enabled?: boolean
    email_enabled?: boolean
    share_with_family?: boolean
    allow_suggestions?: boolean
    data_retention?: '3_months' | '6_months' | '1_year' | 'forever'
}

async function callSupabaseREST(c: any, method: string, path: string, body?: any) {
  const supabaseUrl = c.env.SUPABASE_URL
  const anonKey = c.env.SUPABASE_KEY
  const token = c.get('accessToken')

  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    'apikey': anonKey,
    'Prefer': 'return=representation',
  }

  if (token) {
    headers['Authorization'] = `Bearer ${token}`
  }

  const url = `${supabaseUrl}/rest/v1/${path}`
  const options: RequestInit = {
    method,
    headers,
  }

  if (body) {
    options.body = JSON.stringify(body)
  }

  const response = await fetch(url, options)
  const contentType = response.headers.get('content-type')
  let data

  if (contentType && contentType.includes('application/json')) {
    data = await response.json()
  } else {
    data = await response.text()
  }

  return { status: response.status, data }
}

// GET /api/settings - Fetch user settings
settings.get('/api/settings', authMiddleware, async (c) => {
    try {
        const user = c.get('user')
        const token = c.get('accessToken')

        console.log('[Settings GET] User:', user.id)

        // Call Supabase REST API directly
        const { status, data } = await callSupabaseREST(
          c,
          'GET',
          `user_settings?user_id=eq.${user.id}&select=*`
        )

        console.log('[Settings GET] Status:', status, 'Data:', data)

        if (status === 200 && Array.isArray(data) && data.length > 0) {
          return c.json(data[0])
        }

        if (status === 200 && (Array.isArray(data) && data.length === 0 || !Array.isArray(data))) {
          const { status: insertStatus, data: newSettings } = await callSupabaseREST(
            c,
            'POST',
            'user_settings',
            {
              user_id: user.id,
              push_enabled: true,
              email_enabled: true,
              share_with_family: true,
              allow_suggestions: true,
              data_retention: 'forever'
            }
          )

          if (insertStatus === 201 && Array.isArray(newSettings) && newSettings.length > 0) {
            return c.json(newSettings[0])
          }

          return c.json({ error: 'Failed to create settings' }, 500)
        }

        return c.json(data, status)
    } catch (err) {
        console.error('[Settings GET] Exception:', err)
        return c.json({ error: String(err) }, 500)
    }
})

// PUT /api/settings - Update user settings
settings.put('/api/settings', authMiddleware, async (c) => {
    try {
        const user = c.get('user')
        const body = await c.req.json() as UpdateSettingsRequest

        const updates: Partial<UpdateSettingsRequest> = {}
        if (body.push_enabled !== undefined) updates.push_enabled = body.push_enabled
        if (body.email_enabled !== undefined) updates.email_enabled = body.email_enabled
        if (body.share_with_family !== undefined) updates.share_with_family = body.share_with_family
        if (body.allow_suggestions !== undefined) updates.allow_suggestions = body.allow_suggestions
        if (body.data_retention !== undefined) updates.data_retention = body.data_retention

        const { status, data } = await callSupabaseREST(
          c,
          'PATCH',
          `user_settings?user_id=eq.${user.id}`,
          updates
        )

        if (status === 200 && Array.isArray(data) && data.length > 0) {
          return c.json(data[0])
        }

        return c.json(data, status)
    } catch (err) {
        console.error('[Settings PUT] Exception:', err)
        return c.json({ error: String(err) }, 500)
    }
})

export default settings
