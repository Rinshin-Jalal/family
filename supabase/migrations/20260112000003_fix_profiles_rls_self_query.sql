-- =========================================================================
-- FIX RLS POLICY FOR PROFILE SELF-QUERIES
-- =========================================================================
-- Update the profiles RLS SELECT policy to allow users to query their own profile
-- even when auth context might not be set correctly

DROP POLICY IF EXISTS "Users can view family profiles" ON profiles;

CREATE POLICY "Users can view family profiles" ON profiles
    FOR SELECT USING (
        family_id IN (SELECT family_id FROM profiles WHERE auth_user_id = auth.uid())
        OR auth_user_id = auth.uid()
    );
