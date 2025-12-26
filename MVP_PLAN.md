# Family+ MVP Plan (2 Weeks)

**Tech Stack:**
*   **Backend:** Cloudflare Workers (Hono), D1 (Database), R2 (Audio Storage), Queues (Async processing).
*   **Frontend:** iOS Native (SwiftUI, AVFoundation).
*   **External:** Twilio (Voice capture), OpenAI/CF Workers AI (Transcription).

---

## Week 1: Foundation & The "Capture" Loop
**Goal:** A backend that can receive a phone call, record it, and save it. An iOS app that can log in and see a list of (silent) stories.

### Days 1-2: Backend Setup (The Rails)
*   **Infrastructure:**
    *   Initialize Cloudflare Worker project with Hono (`npm create hono@latest`).
    *   Setup `wrangler.toml` with D1 database binding (`DB`) and R2 bucket binding (`AUDIO_BUCKET`).
*   **Database Schema (D1):**
    *   `Users`: id, phone, name, family_id, role (admin/elder/member).
    *   `Families`: id, invite_code.
    *   `Stories`: id, elder_id, recording_url, transcription_text, status (processing/ready), created_at.
*   **Auth API:**
    *   `POST /auth/login`: Simple phone/OTP or mock auth for MVP.
    *   `POST /family/create`: Creates a new family group.
    *   `POST /family/invite`: Generates an invite code.

### Days 3-4: The Telephony Integration (Twilio + Hono)
*   **Twilio Setup:** Buy a number. Configure webhook URL to your CF Worker.
*   **Voice Webhook (`POST /webhooks/voice`):**
    *   Hono endpoint that returns TwiML (Twilio Markup XML).
    *   Logic: Play greeting -> `<Record>` input -> Action URL to `/webhooks/record-complete`.
*   **Recording Handler (`POST /webhooks/record-complete`):**
    *   Receive the `RecordingUrl` from Twilio.
    *   **CRITICAL:** Don't download/re-upload immediately (timeout risk). Save the *URL* to D1 `Stories` table with status `PENDING_DOWNLOAD`.
    *   Trigger a Cloudflare Queue message: `{"storyId": "xyz", "twilioUrl": "..."}`.

### Days 5-7: iOS Skeleton & Async Processing
*   **Backend (Worker Queue Consumer):**
    *   Consume queue message.
    *   Fetch audio from Twilio -> Stream upload to **R2 Bucket**.
    *   Update `Stories` record with R2 public URL.
    *   (Optional MVP+) Send to CF Workers AI (Whisper) for transcription.
*   **Frontend (Swift):**
    *   **Project Init:** SwiftUI, MVVM structure.
    *   **Auth Flow:** Login Screen -> OTP Input -> Save JWT in Keychain.
    *   **Home View (Tab 1):** Fetch `GET /stories`. Display a list of "Pending Stories".
    *   **Data Models:** `Story`, `User`.

---

## Week 2: Consumption & The "Reaction" Loop
**Goal:** Playing the audio in the app and recording voice replies (Threads).

### Days 8-9: Playback & Feed (Frontend Focus)
*   **Backend:**
    *   `GET /stories`: Return JSON list with signed R2 URLs.
*   **Frontend:**
    *   **Audio Player:** Implement `AVPlayer` wrapper. Custom UI (Play/Pause, Scrubber).
    *   **Feed UI:** Card view for each story. Show Title (or date), Elder Name, Audio Player.
    *   **Polishing:** "Pull to Refresh" to check for new calls.

### Days 10-11: Story Threads (The "Killer Feature")
*   **Backend:**
    *   New Table: `Comments` (id, story_id, user_id, audio_url).
    *   `POST /stories/:id/reply`: Endpoint to accept raw audio file upload (multipart/form-data).
    *   Save reply to R2, entry to D1.
*   **Frontend:**
    *   **Recorder Component:** specialized button: Hold to record, release to stop.
    *   **Upload Logic:** `URLSession` upload task to the reply endpoint.
    *   **Thread View:** Tap a story -> Expand to see list of voice bubbles (replies).

### Days 12-13: Scheduler & Notifications (The "Trigger")
*   **Backend (Scheduled Events):**
    *   Add specific `crons` in `wrangler.toml`.
    *   `scheduled()` handler in Hono: Query `Users` (Elders) who are due for a call -> Trigger Twilio Outbound Call API.
*   **Frontend:**
    *   Local Notifications: "New story from Grandpa!" (Simulated via polling/background fetch for MVP, real APNS is too complex for Week 2).

### Day 14: Polish & Demo Day
*   **Final Integration:** Ensure the loop works: Trigger Call -> Elder Speaks -> App Shows It -> Child Replies.
*   **Cleanup:** Error handling for failed uploads. Loading states.
*   **Ship:** TestFlight Internal build.

---

## MVP Scope Cuts (What we are NOT doing)
*   No fancy AI auto-titling (just use Date/Time).
*   No "Family Tree" visualization (just a list).
*   No Payment/Subscription integration (Free for MVP).
*   No complex editing/trimming of audio.
