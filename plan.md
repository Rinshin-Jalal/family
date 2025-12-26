### **TOOLS & RESOURCES PREP (Day 0)**
*   **Supabase:** Create project, enable Auth (Apple), enable Database, enable Storage.
*   **Twilio:** Purchase a phone number, get Account SID/Auth Token.
*   **OpenAI:** Generate API Key (GPT-4o, Whisper, DALL-E 3).
*   **Xcode:** Create new SwiftUI project, install Supabase SDK via SPM.

---

### **SPRINT 1: THE FOUNDATION (Week 1)**
**Goal:** Users can sign up, create a family, and see an empty app.

#### **Tasks:**
1.  **Database Setup:** Execute the **SQL Schema** (Families, Profiles, Prompts, Stories tables).
2.  **Authentication (iOS):** Implement **"Sign in with Apple."**
    *   *Requirement:* Pass metadata (Name, Email) to Supabase.
3.  **Trigger Logic:** Implement the `handle_new_user` trigger in Supabase.
    *   *Test:* Sign up -> Check `profiles` table -> Verify user is linked to a family.
4.  **Deep Linking (iOS):** Configure `storyride.app/join/:slug`.
    *   *Logic:* Extract slug from URL -> Pass to `raw_user_meta_data` on Sign In.
5.  **Basic Navigation:** Build a `ContentView` with a TabView (Feed, Studio, Settings).

**Success Criteria:**
*   [ ] I can sign up via Apple.
*   [ ] A "Family" is automatically created for me.
*   [ ] I can copy an Invite Link, open it on Safari, sign up, and be added to the *same* family.

---

### **SPRINT 2: THE PHONE AI PROOF OF CONCEPT (Week 2)**
**Goal:** Grandma receives a call, tells a story, and it appears in the app.

#### **Tasks:**
1.  **Twilio Setup:** Configure a Twilio Webhook to point to a Supabase Edge Function.
2.  **The "Bot" Logic (Edge Function):**
    *   Receive call.
    *   Return TwiML (XML) to say: "Hi, this is StoryRide. Tell me a story."
    *   Record the audio.
3.  **Data Ingestion:**
    *   When call ends, Twilio sends a webhook with the Recording URL.
    *   Edge Function downloads MP3 -> Uploads to Supabase Storage -> Inserts record into `responses`.
4.  **Elder Profile:** Create an `add_elder_to_family` function. Call this from the iOS app (Add Grandma screen) so the bot knows who to call.

**Success Criteria:**
*   [ ] I add a phone number in the app.
*   [ ] That number receives a call.
*   [ ] After the call, an audio file appears in the Database.

---

### **SPRINT 3: THE CORE LOOP (Week 3)**
**Goal:** The iOS App can fetch and play the Phone AI story.

#### **Tasks:**
1.  **Data Fetching:** Write a Supabase Query to fetch `stories` + `responses` + `profiles` (User info).
2.  **The Feed View:** Build a `FeedView` (SwiftUI).
    *   Display a list of Stories.
    *   Show "Voice Count" (e.g., "1 Voice").
3.  **The Player View:** Build a `PlayerView`.
    *   Play the MP3 using `AVPlayer`.
    *   Show the transcription text (if available).
4.  **Basic Recording (In-App):**
    *   Add a "Record" button in the Studio.
    *   Use `AVAudioRecorder` to capture audio.
    *   Upload to Supabase Storage + Insert into `responses`.

**Success Criteria:**
*   [ ] I can hear Grandma's story in the app.
*   [ ] I can record my own reply in the app and hear it back.

---

### **SPRINT 4: THE ADAPTIVE UI (Week 4)**
**Goal:** The app looks different for Teens, Parents, and Children.

#### **Tasks:**
1.  **Design System:** Create `Color` and `Font` extensions (Teen/Parent/Child tokens).
2.  **State Management:** Create `AppState` ObservableObject.
    *   Variable: `currentPersona`.
3.  **The Switcher:** Build the Profile Switcher UI (Top Right Dropdown).
4.  **Apply Styles:**
    *   Refactor `FeedView` to use `@EnvironmentObject var appState`.
    *   Apply `.background(appState.currentPersona.themeColor)`.
    *   Apply `.font(appState.currentPersona.fontType)`.
5.  **Child Mode Tweaks:**
    *   Hide Navigation Bar.
    *   Enlarge buttons.
    *   Implement TTS (Text-to-Speech) for Prompts.

**Success Criteria:**
*   [ ] Tapping "Mia (Child)" turns the background white and buttons huge.
*   [ ] Tapping "Leo (Teen)" turns the background black and fonts serif.

---

### **SPRINT 5: THE MULTIPLAYER ENGINE (Week 5)**
**Goal:** Implement the "Add Perspective" / "That's not how it happened" flow.

#### **Tasks:**
1.  **DB Update:** Add `reply_to_response_id` to `responses` table.
2.  **UI Changes:**
    *   In `PlayerView`, add an **"Add Your Version"** button.
    *   Show the "Context" (e.g., "Grandma said: 'It was a Chevy'").
3.  **Backend Logic:**
    *   When recording via "Add Version", pass the Parent Response ID.
4.  **Timeline Stitching:**
    *   Update the Player to play the *Original* response immediately followed by the *Reply* response.
    *   Add a simple timeline bar (Line with two segments).

**Success Criteria:**
*   [ ] I can listen to Grandma, then immediately record my correction.
*   [ ] The player plays both clips back-to-back automatically.

---

### **SPRINT 6: POLISH & AI INTEGRATION (Week 6)**
**Goal:** Make it look like the PRD (AI Art, Transcriptions).

#### **Tasks:**
1.  **OpenAI Integration (Supabase Edge Function):**
    *   When a `response` is created:
    *   Send audio to **Whisper** -> Get Transcription.
    *   Send text to **DALL-E 3** -> Get Image URL.
    *   Update `response` record with data.
2.  **Update UI:**
    *   Display the AI Image in the `StoryCard`.
    *   Display the AI Subtitles in the `PlayerView`.
3.  **Final Polish:**
    *   Add Loading Spinners.
    *   Add Error Handling ("Failed to upload").
    *   Test on Physical Device (Microphone permissions).

**Success Criteria:**
*   [ ] Stories have beautiful AI Art.
*   [ ] I can read the transcript while listening.
*   [ ] App is crash-free on basic flows.

---

### **CHECKLIST FOR LAUNCH (BETA)**

*   **Legal:** Privacy Policy URL uploaded to App Store Connect.
*   **App Store:** Screenshots (Teen Dark Mode, Parent Light Mode, Child Mode).
*   **Subscription:** Configure RevenueCat (or StoreKit) for the "Family Plan."
*   **Costs:** Set up Twilio usage alerts (don't spend $1000 on calls by accident).

### **WHO DOES WHAT? (Suggested)**

*   **Gregb (Full Stack):** Focus on Sprint 2 (Twilio) and Sprint 6 (OpenAI/AI logic).
*   **Rinshin (Frontend/UI):** Focus on Sprint 4 (Adaptive UI) and Sprint 3/5 (Views).
*   **Together:** Sprint 1 (Schema/Auth) & Testing.

