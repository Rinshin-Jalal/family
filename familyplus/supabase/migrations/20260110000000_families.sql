-- Families table
CREATE TABLE IF NOT EXISTS families (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Family members table
CREATE TABLE IF NOT EXISTS family_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'member', -- 'owner', 'admin', 'member'
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(family_id, user_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_families_created_by ON families(created_by);
CREATE INDEX IF NOT EXISTS idx_family_members_family_id ON family_members(family_id);
CREATE INDEX IF NOT EXISTS idx_family_members_user_id ON family_members(user_id);

-- RLS policies
ALTER TABLE families ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_members ENABLE ROW LEVEL SECURITY;

-- Families: owners can view their families
CREATE POLICY "Users can view families they belong to"
    ON families FOR SELECT
    USING (
        id IN (SELECT family_id FROM family_members WHERE user_id = auth.uid())
    );

-- Family members: users can view family memberships
CREATE POLICY "Users can view family members in their families"
    ON family_members FOR SELECT
    USING (
        family_id IN (SELECT family_id FROM family_members WHERE user_id = auth.uid())
    );

-- Family members: users can insert themselves into families
CREATE POLICY "Users can insert themselves into families"
    ON family_members FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- Families: authenticated users can create families
CREATE POLICY "Authenticated users can create families"
    ON families FOR INSERT
    WITH CHECK (created_by = auth.uid());
