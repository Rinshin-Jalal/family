
-- =========================================================================
-- STORYRIDE - FULL DATABASE SCHEMA V2.0
-- Includes: Auth, Families, Multiplayer Responses, Adaptive UI Support, RLS
-- =========================================================================

-- 1. EXTENSIONS
-- =========================================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. ENUMS (Defining the "Rules" of the data)
-- =========================================================================
CREATE TYPE user_role AS ENUM ('organizer', 'elder', 'member', 'child');
CREATE TYPE response_source AS ENUM ('phone_ai', 'app_audio', 'app_text');
CREATE TYPE plan_tier AS ENUM ('starter', 'standard', 'extended');

-- 3. TABLES (The Structure)
-- =========================================================================

-- FAMILIES: The Subscription Unit
CREATE TABLE families (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    
    -- The "Magic Link" Slug: e.g., "storyride.app/join/abc12"
    invite_slug TEXT UNIQUE NOT NULL,
    
    plan_tier plan_tier DEFAULT 'starter',
    stripe_customer_id VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- PROFILES: Links Auth Users to Families (Supports "Shadow Profiles" for Elders)
CREATE TABLE profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- If NULL, this is an Elder (Phone-only). If set, this is an App User.
    auth_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    
    family_id UUID REFERENCES families(id) ON DELETE CASCADE,
    
    full_name VARCHAR(100),
    avatar_url TEXT,
    role user_role DEFAULT 'member',
    
    -- Only used for Elders to receive phone calls
    phone_number VARCHAR(20),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- PROMPTS: The Questions
CREATE TABLE prompts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID REFERENCES families(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    category VARCHAR(50), -- e.g., childhood, holidays, funny
    is_custom BOOLEAN DEFAULT FALSE,
    
    -- When the AI should call (if automated) or when it appears in app
    scheduled_for TIMESTAMPTZ, 
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- STORIES: The Compiled "StoryRide" (The Output)
CREATE TABLE stories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    prompt_id UUID REFERENCES prompts(id) ON DELETE CASCADE,
    family_id UUID REFERENCES families(id) ON DELETE CASCADE,
    
    title TEXT, -- AI Generated Title
    summary_text TEXT, -- AI Generated Summary
    cover_image_url TEXT, -- AI Generated Cover
    
    -- Multiplayer Metric
    voice_count INT DEFAULT 1, 
    
    is_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RESPONSES: The Raw Input (The Multiplayer Thread)
CREATE TABLE responses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    prompt_id UUID REFERENCES prompts(id) ON DELETE CASCADE,
    story_id UUID REFERENCES stories(id) ON DELETE CASCADE, -- Links back to the main story
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE, -- The Speaker
    
    source response_source NOT NULL,
    
    media_url TEXT, -- Supabase Storage URL for Audio
    transcription_text TEXT, -- Whisper Output
    duration_seconds INT,
    processing_status VARCHAR(20) DEFAULT 'pending', -- pending, completed, failed
    
    -- MULTIPLAYER LOGIC: If this is a reply/correction, link it to the light response
    reply_to_response_id UUID REFERENCES responses(id),
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- STORY_PANELS: The Visual Breakdown (The "Comic" Panels)
CREATE TABLE story_panels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    story_id UUID REFERENCES stories(id) ON DELETE CASCADE,
    
    image_url TEXT NOT NULL, -- AI Generated Image for this scene
    caption TEXT NOT NULL, -- Text to display
    order_index INT NOT NULL, -- Sequence: 1, 2, 3...
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- REACTIONS: The Social Layer
CREATE TABLE reactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    
    target_id UUID NOT NULL, -- ID of the Story or Response
    target_type VARCHAR(20) NOT NULL, -- 'story' or 'response'
    
    emoji VARCHAR(50) NOT NULL, -- e.g., '❤️', '🔥', '😂'
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. ROW LEVEL SECURITY (RLS) POLICIES
-- =========================================================================
-- This ensures users can ONLY see data belonging to their specific family.

ALTER TABLE families ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE prompts ENABLE ROW LEVEL SECURITY;
ALTER TABLE stories ENABLE ROW LEVEL SECURITY;
ALTER TABLE responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE story_panels ENABLE ROW LEVEL SECURITY;
ALTER TABLE reactions ENABLE ROW LEVEL SECURITY;

-- Helper: We use a subquery to find the current user's family_id
-- 'auth.uid()' returns the UUID from Supabase Auth

-- FAMILIES: Users can view their own family
CREATE POLICY "Users can view own family" ON families
    FOR SELECT USING (id IN (SELECT family_id FROM profiles WHERE auth_user_id = auth.uid()));

-- PROFILES: Users can view profiles in their family
CREATE POLICY "Users can view family profiles" ON profiles
    FOR SELECT USING (family_id IN (SELECT family_id FROM profiles WHERE auth_user_id = auth.uid()));

-- PROMPTS: Users can view their family's prompts
CREATE POLICY "Users can view family prompts" ON prompts
    FOR SELECT USING (family_id IN (SELECT family_id FROM profiles WHERE auth_user_id = auth.uid()));

-- STORIES: Users can view their family's stories
CREATE POLICY "Users can view family stories" ON stories
    FOR SELECT USING (family_id IN (SELECT family_id FROM profiles WHERE auth_user_id = auth.uid()));

-- RESPONSES: Users can view responses linked to their family's prompts/stories
CREATE POLICY "Users can view family responses" ON responses
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM stories 
            WHERE stories.id = responses.story_id 
            AND stories.family_id IN (SELECT family_id FROM profiles WHERE auth_user_id = auth.uid())
        )
    );

-- STORY PANELS: Linked to stories, so inherit story policy
CREATE POLICY "Users can view story panels" ON story_panels
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM stories 
            WHERE stories.id = story_panels.story_id 
            AND stories.family_id IN (SELECT family_id FROM profiles WHERE auth_user_id = auth.uid())
        )
    );

-- REACTIONS: Users can view reactions on their family's content
CREATE POLICY "Users can view family reactions" ON reactions
    FOR SELECT USING (
        user_id IN (SELECT id FROM profiles WHERE family_id IN (SELECT family_id FROM profiles WHERE auth_user_id = auth.uid()))
    );

-- INSERT POLICIES: Users can insert reactions and stories (if they belong to the family)
CREATE POLICY "Users can insert reactions" ON reactions
    FOR INSERT WITH CHECK (user_id = (SELECT id FROM profiles WHERE auth_user_id = auth.uid()));

-- 5. FUNCTIONS & TRIGGERS (The Logic)
-- =========================================================================

-- FUNCTION: handle_new_user
-- Handles the "Sign in with Apple" + "Invite Link" logic automatically.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    v_invite_slug TEXT;
    v_family_id UUID;
    v_role user_role;
BEGIN
    -- 1. Check if user came from an Invite Link (metadata passed from iOS app)
    v_invite_slug := new.raw_user_meta_data->>'invite_slug';
    
    -- 2. Check if a specific role was requested (optional logic)
    IF new.raw_user_meta_data ? 'role' THEN
        v_role := (new.raw_user_meta_data->>'role')::user_role;
    ELSE
        v_role := 'member';
    END IF;

    IF v_invite_slug IS NOT NULL THEN
        -- SCENARIO: Joining an existing family
        SELECT id INTO v_family_id FROM families WHERE invite_slug = v_invite_slug;
        
        IF v_family_id IS NOT NULL THEN
            INSERT INTO public.profiles (auth_user_id, family_id, full_name, avatar_url, role)
            VALUES (
                new.id, 
                v_family_id, 
                new.raw_user_meta_data->>'full_name', 
                new.raw_user_meta_data->>'avatar_url',
                v_role
            );
        END IF;
    ELSE
        -- SCENARIO: Creating a NEW Family (This user is the Organizer)
        -- Generate a random 8-char slug for their family link
        v_invite_slug := lower(substring(encode(gen_random_bytes(16), 'hex'), 1, 8));
        
        INSERT INTO public.families (name, invite_slug)
        VALUES (new.raw_user_meta_data->>'family_name', v_invite_slug)
        RETURNING id INTO v_family_id;

        -- Create Organizer Profile
        INSERT INTO public.profiles (auth_user_id, family_id, full_name, avatar_url, role)
        VALUES (
            new.id, 
            v_family_id, 
            new.raw_user_meta_data->>'full_name', 
            new.raw_user_meta_data->>'avatar_url',
            'organizer'
        );
    END IF;

    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- TRIGGER: Run the function whenever a user signs up
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();


-- FUNCTION: add_elder_to_family
-- Helper for the App to add Grandma without her logging in.
CREATE OR REPLACE FUNCTION add_elder_to_family(p_family_id UUID, p_phone VARCHAR, p_name VARCHAR)
RETURNS UUID AS $$
DECLARE
    new_profile_id UUID;
BEGIN
    INSERT INTO public.profiles (family_id, phone_number, full_name, role, auth_user_id)
    VALUES (p_family_id, p_phone, p_name, 'elder', NULL)
    RETURNING id INTO new_profile_id;
    
    RETURN new_profile_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 6. INDEXES (Performance)
-- =========================================================================
create index idx_profiles_auth_user on profiles(auth_user_id);
create index idx_profiles_family on profiles(family_id);
create index idx_profiles_phone on profiles(phone_number); -- For looking up elders

create index idx_families_slug on families(invite_slug);

create index idx_prompts_family on prompts(family_id);
create index idx_prompts_scheduled on prompts(scheduled_for);

create index idx_stories_family on stories(family_id);
create index idx_stories_prompt on stories(prompt_id);

create index idx_responses_story on responses(story_id);
create index idx_responses_prompt on responses(prompt_id);
create index idx_responses_reply_to on responses(reply_to_response_id);

create index idx_panels_story on story_panels(story_id);

create index idx_reactions_target on reactions(target_id, target_type);

-- 7. VIEWS (Common Queries)
-- =========================================================================
-- HOME_FEED_VIEW: Joins Stories, Prompts, and Latest Activity for the App
CREATE VIEW home_feed AS
SELECT 
    s.id as story_id,
    s.title,
    s.cover_image_url,
    s.created_at,
    s.voice_count,
    p.text as prompt_text,
    p.category as prompt_category,
    -- Count reactions
    (SELECT COUNT(*) FROM reactions WHERE target_id = s.id AND target_type = 'story') as reaction_count
FROM stories s
JOIN prompts p ON s.prompt_id = p.id
ORDER BY s.created_at DESC;
