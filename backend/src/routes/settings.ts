//
//  User Settings Routes
//  API endpoints for managing user notification, privacy, and preference settings
//

import { Hono } from 'hono'
import { authMiddleware, profileMiddleware } from '../middleware/auth'

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

// GET /api/settings - Fetch user settings
settings.get('/api/settings', authMiddleware, profileMiddleware, async (c) => {
    const supabase = c.get('supabase')
    const user = c.get('user')

    // Query by auth.users.id (matches the user_settings table schema)
    const { data, error } = await supabase
        .from('user_settings')
        .select('*')
        .eq('user_id', user.id)
        .single<UserSettings>()

    // If no settings exist, create defaults
    if (error || !data) {
        const { data: newSettings, error: insertError } = await supabase
            .from('user_settings')
            .insert({
                user_id: user.id,
                push_enabled: true,
                email_enabled: true,
                share_with_family: true,
                allow_suggestions: true,
                data_retention: 'forever'
            })
            .select()
            .single<UserSettings>()

        if (insertError) {
            return c.json({ error: insertError.message }, 500)
        }

        return c.json(newSettings)
    }

    return c.json(data)
})

// PUT /api/settings - Update user settings
settings.put('/api/settings', authMiddleware, profileMiddleware, async (c) => {
    const supabase = c.get('supabase')
    const user = c.get('user')
    const body = await c.req.json() as UpdateSettingsRequest

    // Build update object with only provided fields
    const updates: Partial<UpdateSettingsRequest> = {}
    if (body.push_enabled !== undefined) updates.push_enabled = body.push_enabled
    if (body.email_enabled !== undefined) updates.email_enabled = body.email_enabled
    if (body.share_with_family !== undefined) updates.share_with_family = body.share_with_family
    if (body.allow_suggestions !== undefined) updates.allow_suggestions = body.allow_suggestions
    if (body.data_retention !== undefined) updates.data_retention = body.data_retention

    const { data, error } = await supabase
        .from('user_settings')
        .update(updates)
        .eq('user_id', user.id)
        .select()
        .single<UserSettings>()

    if (error) {
        return c.json({ error: error.message }, 500)
    }

    return c.json(data)
})

export default settings
