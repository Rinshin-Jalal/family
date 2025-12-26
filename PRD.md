# PRODUCT REQUIREMENTS DOCUMENT (PRD)
**Project Name:** StoryRide
**Version:** 2.0 (Final Release)
**Status:** Development Ready
**Date:** December 2025

---

## **1. EXECUTIVE SUMMARY**

**StoryRide** is the first **multiplayer, multi-generational storytelling platform**. Unlike static "memory vault" apps (e.g., Remento, StoryWorth) which operate on a "One Storyteller -> Many Consumers" model, StoryRide treats family history as a **living, collaborative thread**.

Our competitive advantage is the **"That’s Not How It Happened" Loop**:
1.  **Grandparent** tells a story (via Phone AI).
2.  **Parent/Teen** listens and adds a correction, detail, or reaction ("Actually, we were driving a Ford, not a Chevy").
3.  **The AI** weaves these conflicting/added perspectives into a single, rich "StoryRide" with dynamic visuals.

The app features a revolutionary **Adaptive UI System**, transforming the interface based on who is holding the device—from an "Aesthetic Archive" for Teens to a "Digital Storybook" for Children, while Elders interact solely via empathetic phone calls.

---

## **2. THE COMPETITIVE GAP**

| Feature | **Competitors (Remento, StoryWorth, Klokbox)** | **StoryRide (Us)** |
| :--- | :--- | :--- |
| **Interaction Model** | One-Way (Grandparent records -> Family listens). | **Multiplayer** (Everyone adds/corrects/debates). |
| **Delivery** | Link-based forms or complex apps. | **Hybrid:** Phone AI for Elders + Adaptive App for Family. |
| **Engagement** | "Chore" based (weekly homework). | **Social/Habit** based (FOMO on family threads). |
| **Visuals** | Static books or photo grids. | **Cinematic:** AI-generated art that reacts to who is speaking. |
| **Teen Appeal** | Low (Feels like an assignment). | **High:** Aesthetic, dark-mode, social feed style. |

---

## **3. TARGET AUDIENCE & PERSONAS**

We serve **4 Personas** simultaneously within one family subscription.

| Persona | **Teen (16-22)** | **Parent (25-45)** | **Child (3-12)** | **Elder (70+)** |
| :--- | :--- | :--- | :--- | :--- |
| **Core Desire** | Self-expression, aesthetic curation. | Legacy, organization, connection. | Play, imitation. | Being heard, remembrance. |
| **Frustration** | "This looks like a baby app." | "I never get around to interviewing them." | "Reading/Typing is hard." | "I don't understand this screen." |
| **Experience** | **Aesthetic/Minimalist.** Dark mode, serif fonts, exportable art. | **Clean/Controlled.** Dashboard view, prompt manager. | **Audio-First.** Big buttons, spoken prompts, rewards. | **Phone-Only.** No app. Empathetic AI calls. |

---

## **4. DESIGN SYSTEM: "THE AESTHETIC ARCHIVE"**

The UI is built on an **Adaptive Architecture**. The data remains constant, but the "Skin" morphs instantly via a Profile Switcher.

### **4.1 Core Principles**
1.  **Cinematic Over Clutter:** The UI is a frame for the content.
2.  **Dignified Playfulness:** Never "cartoonish." Use sophistication for older users and tactility for younger ones.
3.  **Typography-Led:** Words carry emotion.

### **4.2 Adaptive Matrix**

| Element | **Teen Mode** | **Parent Mode** | **Child Mode** |
| :--- | :--- | :--- | :--- |
| **Background** | Deep Black (`#000000`) | Paper White (`#F5F5F7`) | Pure White (`#FFFFFF`) |
| **Accent** | Electric Indigo (`#5856D6`) | Trust Blue | Playful Orange (`#FF9500`) |
| **Font** | **New York Serif** (Titles) | SF Pro (Clean) | SF Rounded (Playful) |
| **Layout** | Full-screen, edge-to-edge. | Masonry Grid, organized. | One giant card, no scroll. |
| **Navigation** | Minimalist Dock. | Standard Tab Bar. | Hidden (Linear flow). |
| **Input** | Voice + Text. | Voice + Text + Edit. | Voice Only (Audio Q). |

### **4.3 The Profile Switcher**
A top-right dropdown allows instant context switching.
*   *Use Case:* Mom hands iPad to Kid. She taps profile -> "Mia." The UI instantly brightens, buttons grow, and the app reads the prompt aloud.

---

## **5. CORE USER FLOWS**

### **Flow A: The "Multiplayer Thread" (The Happy Path)**
1.  **Incite:** Grandma receives a phone call from AI. Tells the story: "We drove across the country in a Chevy."
2.  **Notify:** Family app updates. Notification: *"Grandma has a new story: 'The Road Trip'."*
3.  **Consume:** Dad opens app (Dark Mode). Plays story. Sees AI art of a car.
4.  **Disrupt:** Dad taps **"Add Perspective."** Records: *"Actually, Dad, it was a Ford. And you blew a tire in Nevada."*
5.  **Synthesize:** AI processes the "Correction."
    *   *Visual:* The AI art shifts to show a car with a blown tire (Subtle change).
    *   *Audio:* The player timeline now has two segments: Grandma (Orange) -> Dad (Blue).
6.  **React:** Teen sees the "Argument." Sends a "🔥" emoji reaction.

### **Flow B: The Child Experience**
1.  Child opens app. UI is "Storybook Mode."
2.  Prompt is spoken aloud by TTS: *"What is your favorite toy?"*
3.  Child taps Giant Red Mic. Records: "My robot."
4.  Reward: Screen explodes with digital confetti. Child gets a "Robot Sticker."

### **Flow C: The Elder Experience**
1.  Phone rings.
2.  AI Voice: *"Hi [Name], this is StoryRide. [Daughter] wants to know what your favorite childhood game was."*
3.  Elder talks.
4.  AI: *"That was beautiful. I've saved it for the family. Goodbye."*

---

## **6. FUNCTIONAL REQUIREMENTS**

### **6.1 Authentication & Onboarding**
*   **Method:** Sign in with Apple (No SMS).
*   **Invite Flow:** Deep Links (e.g., `storyride.app/join/fam123`).
*   **Shadow Profiles:** Elders exist in DB (`auth_user_id = NULL`) but have no login.

### **6.2 The Studio (Creation)**
*   **Modes:**
    *   **Start New:** Initiates a fresh prompt.
    *   **Add Perspective:** Reply to an existing segment (Multiplayer).
*   **Inputs:**
    *   **Teen/Parent:** Hold-to-record audio or Type text.
    *   **Child:** Giant Mic Button only.
*   **AI Integration:** Real-time waveform visualization.

### **6.3 The Player (The Multiplayer Engine)**
*   **Visualized Thread:** A color-coded timeline bar at the bottom showing who speaks when.
    *   *Grandma Segment:* Orange.
    *   *Dad Segment:* Blue.
    *   *Teen Segment:* Purple.
*   **Dynamic Art:** The background image shifts slightly or changes elements based on the active speaker's context.
*   **Reactions:** Tap-to-react (Heart, Fire, Laugh). Reactions appear as floating bubbles on the video export.

### **6.4 The Phone AI (Telephony)**
*   **Tech:** Twilio + OpenAI Realtime API.
*   **Behavior:** Empathetic, slow, clear.
*   **Safety:** Audio encrypted at rest.

### **6.5 Social & Gamification**
*   **Sharing:** Export 15s clip to Instagram/TikTok (Vertical Video format).
*   **Stickers (Child):** Digital sticker book unlocked by recording.

---

## **7. TECHNICAL ARCHITECTURE**

### **7.1 Tech Stack**
*   **Frontend:** iOS Native (SwiftUI).
*   **Backend:** Supabase (Postgres, Auth, Storage, Edge Functions).
*   **Telephony:** Twilio.
*   **AI:** OpenAI (GPT-4o for context, Whisper for transcription, DALL-E 3 for visuals).

### **7.2 Database Schema (Core)**

```sql
-- 1. ENUMS
CREATE TYPE user_role AS ENUM ('organizer', 'elder', 'member');
CREATE TYPE response_source AS ENUM ('phone_ai', 'app_audio', 'app_text');

-- 2. TABLES
CREATE TABLE families (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    invite_slug TEXT UNIQUE NOT NULL, -- For deep links
    plan_tier VARCHAR(20) DEFAULT 'starter',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    auth_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL, -- NULL for Elders
    family_id UUID REFERENCES families(id) ON DELETE CASCADE,
    full_name VARCHAR(100),
    role user_role DEFAULT 'member',
    phone_number VARCHAR(20),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE prompts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID REFERENCES families(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    scheduled_for TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE responses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    prompt_id UUID REFERENCES prompts(id) ON DELETE CASCADE,
    story_id UUID REFERENCES stories(id) ON DELETE CASCADE, -- The compiled story
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    source response_source NOT NULL,
    
    -- MULTIPLAYER LOGIC
    reply_to_response_id UUID REFERENCES responses(id), -- Links Dad's reply to Grandma's original
    
    media_url TEXT,
    transcription_text TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE stories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    prompt_id UUID REFERENCES prompts(id) ON DELETE CASCADE,
    family_id UUID REFERENCES families(id) ON DELETE CASCADE,
    title TEXT, -- AI Generated
    summary_text TEXT,
    cover_image_url TEXT,
    is_completed BOOLEAN DEFAULT FALSE,
    voice_count INT DEFAULT 1, -- Tracks multiplayer depth
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. TRIGGERS
-- Auto-join family on Apple Sign-in via Invite Slug
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    v_invite_slug TEXT;
    v_family_id UUID;
BEGIN
    v_invite_slug := new.raw_user_meta_data->>'invite_slug';
    
    IF v_invite_slug IS NOT NULL THEN
        SELECT id INTO v_family_id FROM families WHERE invite_slug = v_invite_slug;
        IF v_family_id IS NOT NULL THEN
            INSERT INTO public.profiles (auth_user_id, family_id, full_name, role)
            VALUES (new.id, v_family_id, new.raw_user_meta_data->>'full_name', 'member');
        END IF;
    ELSE
        -- Create new family for organizer
        v_invite_slug := lower(substring(encode(gen_random_bytes(16), 'hex'), 1, 8));
        INSERT INTO public.families (name, invite_slug) VALUES (new.raw_user_meta_data->>'family_name', v_invite_slug)
        RETURNING id INTO v_family_id;
        
        INSERT INTO public.profiles (auth_user_id, family_id, full_name, role)
        VALUES (new.id, v_family_id, new.raw_user_meta_data->>'full_name', 'organizer');
    END IF;
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## **8. METRICS & SUCCESS**

1.  **Multiplayer Rate:** % of Stories with >1 contributor (Target: >40%).
2.  **Retention:** Week 1 and Week 4 retention for Parents/Teens (Target: >35%).
3.  **Engagement:** Avg number of "Perspectives" (Replies) per Story.
4.  **Revenue:** Family Subscription Churn < 5%.

---

## **9. ROADMAP**

**Phase 1 (MVP - "The Thread"):**
*   Adaptive UI (Teen/Parent/Child).
*   Phone AI for Elders.
*   Multiplayer "Add Perspective" feature.
*   iOS Launch.

**Phase 2 (Growth - "The Habit"):**
*   TikTok/IG Export.
*   Child Sticker Rewards.
*   Dynamic Art (Reacting to speaker).

**Phase 3 (Scale - "The Archive"):**
*   Android App.
*   Physical Book Printing.