-- =========================================================================
-- FIX RLS POLICIES FOR FAMILY CREATION AND PROFILE UPDATES
-- =========================================================================
-- This migration adds missing RLS policies needed for:
-- 1. Users to create new families
-- 2. Users to update their own profile (family_id assignment)
-- 3. Users to update family invite slugs (organizer only)
-- 4. Trigger function to insert profiles when users sign up

-- 1. INSERT policy for families: Users can create families
CREATE POLICY "Users can create families" ON families
    FOR INSERT WITH CHECK (true);

-- 2. UPDATE policy for profiles: Users can update their own profile
CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (auth_user_id = auth.uid())
    WITH CHECK (auth_user_id = auth.uid());

-- 3. UPDATE policy for families: Only organizers can update
-- (Used when regenerating invite slugs)
CREATE POLICY "Organizers can update family" ON families
    FOR UPDATE USING (
        id IN (
            SELECT family_id FROM profiles 
            WHERE auth_user_id = auth.uid() 
            AND role = 'organizer'
        )
    )
    WITH CHECK (
        id IN (
            SELECT family_id FROM profiles 
            WHERE auth_user_id = auth.uid() 
            AND role = 'organizer'
        )
    );

-- 4. INSERT policy for profiles: Allow all insertions (trigger runs as SECURITY DEFINER)
-- The trigger function runs as SECURITY DEFINER with SET ROLE postgres, so it can insert
-- directly without needing RLS bypassing. We still add a policy for completeness.
CREATE POLICY "Allow profile insertion" ON profiles
    FOR INSERT WITH CHECK (true);

-- 5. Additional policy for shadow profiles (Elders without auth)
-- Allow inserting profiles with NULL auth_user_id (for Elders added by family organizer)
-- Already covered by above policy, but being explicit
