# Wireframes & Screen Specifications
# Family Memory App

**Version:** 1.0  
**Last Updated:** December 20, 2025

---

## Table of Contents

1. [Onboarding & Setup Flow](#onboarding--setup-flow)
2. [Elder Experience](#elder-experience)
3. [Main App Screens](#main-app-screens)
4. [Story & Threading Screens](#story--threading-screens)
5. [Family Tree Screens](#family-tree-screens)
6. [Profile & Settings](#profile--settings)
7. [Admin Dashboard (Web)](#admin-dashboard-web)

---

## Design System Overview

### Visual Principles
- **Warm & Emotional:** Photography-heavy, family-focused
- **Simple Navigation:** Max 2 taps to any core feature
- **Voice-First UI:** Large record buttons, minimal typing
- **Generational Accessibility:** Large text options, high contrast
- **Trust & Privacy:** Visual indicators of private/family-only content

### Color Palette
- **Primary:** Warm amber/gold (#F59E0B) - heritage, wisdom
- **Secondary:** Deep navy (#1E3A8A) - trust, stability  
- **Accent:** Soft coral (#FB7185) - warmth, connection
- **Neutral:** Warm grays (#78716C to #F5F5F4)
- **Success:** Sage green (#10B981)
- **Alert:** Soft red (#EF4444)

### Typography
- **Headings:** Serif font (Georgia, Playfair) - traditional, heirloom feel
- **Body:** Sans-serif (Inter, SF Pro) - modern, readable
- **Large text mode** available for elders

### Key UI Elements
- **Story Cards:** Photo + title + duration + family member avatar
- **Record Button:** Large, circular, red when recording
- **Thread Indicators:** Branching lines showing responses
- **Notification Badges:** Number of unheard stories/responses

---

## 1. Onboarding & Setup Flow

### Screen 1.1: Welcome / Landing
```
┌─────────────────────────────────────┐
│                                     │
│          [Family Photo]             │
│                                     │
│    Capture Your Family's Stories    │
│       Before They're Gone           │
│                                     │
│  Voice-first memory keeping that    │
│  turns your elders' stories into    │
│  a private family podcast           │
│                                     │
│  ┌───────────────────────────────┐  │
│  │   Get Started - It's Free     │  │
│  └───────────────────────────────┘  │
│                                     │
│         Already have account?       │
│              Sign In                │
│                                     │
└─────────────────────────────────────┘
```

**Elements:**
- Hero image: Multi-generational family photo (stock or illustration)
- Headline: Emotional hook about preservation + urgency
- Subheadline: Clear value prop in one sentence
- CTA button: Primary action (large, prominent)
- Secondary link: Sign in (small, subtle)

**Interactions:**
- Tap "Get Started" → Screen 1.2
- Tap "Sign In" → Login screen

---

### Screen 1.2: Account Creation
```
┌─────────────────────────────────────┐
│  ←                         Step 1/5 │
│                                     │
│     Let's Create Your Account       │
│                                     │
│  ┌─────────────────────────────────┐│
│  │ Name                            ││
│  │ [________________]              ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │ Email                           ││
│  │ [________________]              ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │ Phone                           ││
│  │ [________________]              ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │ Password                        ││
│  │ [________________] 👁           ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌───────────────────────────────┐  │
│  │         Continue              │  │
│  └───────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

**Elements:**
- Progress indicator: Step 1/5 (top right)
- Back button (top left)
- Form fields: Name, Email, Phone, Password
- Password visibility toggle
- Continue button (disabled until all fields valid)

**Validation:**
- Email format check
- Password strength indicator
- Phone number format (international support)

**Interactions:**
- Fill all fields → Button enables
- Tap Continue → Screen 1.3

---

### Screen 1.3: Family Setup
```
┌─────────────────────────────────────┐
│  ←                         Step 2/5 │
│                                     │
│      Name Your Family               │
│                                     │
│  This is your private family space  │
│                                     │
│  ┌─────────────────────────────────┐│
│  │ Family Name                     ││
│  │ [The Johnsons]                  ││
│  └─────────────────────────────────┘│
│                                     │
│  Examples: "The Smiths"             │
│            "Johnson Family"         │
│            "Patel Clan"             │
│                                     │
│                                     │
│  ┌───────────────────────────────┐  │
│  │         Continue              │  │
│  └───────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

**Elements:**
- Progress: Step 2/5
- Input field: Family name
- Helper text: Examples to guide user
- Continue button

**Interactions:**
- Enter family name → Continue
- Tap Continue → Screen 1.4

---

### Screen 1.4: Add Elder
```
┌─────────────────────────────────────┐
│  ←                         Step 3/5 │
│                                     │
│   Who's Story Should We Capture?    │
│                                     │
│  Start with one elder (grandparent, │
│  parent) who has stories to share   │
│                                     │
│  ┌─────────────────────────────────┐│
│  │ [Upload Photo] or 📷            ││
│  │     ┌───────┐                   ││
│  │     │ 👤    │                   ││
│  │     └───────┘                   ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │ Their Name                      ││
│  │ [Grandpa Joe]                   ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │ Relationship to You             ││
│  │ [Grandfather ▼]                 ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │ Their Phone Number              ││
│  │ [+1 (555) 123-4567]             ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌───────────────────────────────┐  │
│  │         Continue              │  │
│  └───────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

**Elements:**
- Photo upload (circular avatar)
- Name input
- Relationship dropdown (Grandfather, Grandmother, Father, Mother, Uncle, Aunt, Other)
- Phone number input (formatted)
- Continue button

**Interactions:**
- Tap photo area → Camera or photo library picker
- Fill all fields → Continue enabled
- Tap Continue → Screen 1.5

---

### Screen 1.5: Schedule Calls
```
┌─────────────────────────────────────┐
│  ←                         Step 4/5 │
│                                     │
│  When Should We Call Grandpa Joe?   │
│                                     │
│  We'll call at the same time each   │
│  week. Choose a time that works     │
│  best for them.                     │
│                                     │
│  ┌─────────────────────────────────┐│
│  │ Day of Week                     ││
│  │ [Wednesday ▼]                   ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │ Time                            ││
│  │ [10:00 AM ▼]                    ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │ Their Timezone                  ││
│  │ [EST (GMT-5) ▼]                 ││
│  └─────────────────────────────────┘│
│                                     │
│  ⓘ They can also call us anytime   │
│     at 1-800-FAMILY-STORY           │
│                                     │
│  ┌───────────────────────────────┐  │
│  │    Schedule First Call        │  │
│  └───────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

**Elements:**
- Day picker (dropdown)
- Time picker (dropdown in 30-min intervals)
- Timezone selector
- Info callout: Alternative call-in number
- Schedule button

**Validation:**
- Warn if unusual time (too early/late)
- Show next scheduled call date

**Interactions:**
- Select all options → Button enables
- Tap Schedule → Screen 1.6

---

### Screen 1.6: Invite Family
```
┌─────────────────────────────────────┐
│  ←                         Step 5/5 │
│                                     │
│     Invite Your Family              │
│                                     │
│  Family memories are better when    │
│  everyone contributes. Invite at    │
│  least 3 people to get started.     │
│                                     │
│  ┌─────────────────────────────────┐│
│  │ 📧 Email or 📱 Phone            ││
│  │ [_________________]  [+ Add]    ││
│  └─────────────────────────────────┘│
│                                     │
│  Added (3):                         │
│  ┌─────────────────────────────────┐│
│  │ 👤 Mom              [Remove]    ││
│  │ 📧 mom@email.com                ││
│  ├─────────────────────────────────┤│
│  │ 👤 Sister           [Remove]    ││
│  │ 📧 sister@email.com             ││
│  ├─────────────────────────────────┤│
│  │ 👤 Brother          [Remove]    ││
│  │ 📱 +1 555-234-5678              ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌───────────────────────────────┐  │
│  │    Send Invites & Finish      │  │
│  └───────────────────────────────┘  │
│                                     │
│  ⏭ Skip for now                    │
│                                     │
└─────────────────────────────────────┘
```

**Elements:**
- Input field: Email or phone
- Add button
- List of added family members
- Remove buttons for each
- Send invites button (primary)
- Skip link (secondary)

**Validation:**
- Min 3 family members recommended
- Email/phone format validation

**Interactions:**
- Add 3+ people → Button emphasizes
- Tap Send Invites → Confirmation screen → Main app
- Tap Skip → Main app (with prompt to invite later)

---

### Screen 1.7: Setup Complete
```
┌─────────────────────────────────────┐
│                                     │
│              🎉                     │
│                                     │
│       You're All Set!               │
│                                     │
│  Grandpa Joe's first call is        │
│  scheduled for:                     │
│                                     │
│  📅 Wednesday, Dec 27 at 10:00 AM   │
│                                     │
│  We'll send you a notification when │
│  his first story is ready to hear.  │
│                                     │
│                                     │
│  ┌───────────────────────────────┐  │
│  │    Go to Family Stories       │  │
│  └───────────────────────────────┘  │
│                                     │
│  ⓘ Want to test it? Call           │
│     1-800-FAMILY-STORY now          │
│                                     │
└─────────────────────────────────────┘
```

**Elements:**
- Success icon/animation
- Confirmation message
- Next scheduled call details
- What happens next explanation
- CTA to enter app
- Info: Test call option

**Interactions:**
- Tap "Go to Family Stories" → Main Home Screen (2.1)

---

## 2. Elder Experience

### Elder Experience 2.1: Automated Call Flow
```
[PHONE CALL - AUDIO ONLY]

┌─────────────────────────────────────┐
│                                     │
│     [ELDER'S PHONE RINGS]           │
│                                     │
│     Caller ID:                      │
│     "The Johnson Family"            │
│     1-800-FAMILY-STORY              │
│                                     │
│     [Photo of family if iPhone]     │
│                                     │
└─────────────────────────────────────┘

ELDER ANSWERS:

SYSTEM (warm, friendly voice):
"Hi Grandpa Joe! This is your Johnson Family 
story keeper. Do you have about 10 minutes 
to share a story today?"

[WAIT FOR RESPONSE]

If YES:
"Wonderful! Today's question is: 
Tell me about your first car. 
What did it look like? How did you get it? 
What adventures did you have?"

[RECORD FOR 5-15 MINUTES]

Gentle prompts if silence:
- "That's interesting, tell me more..."
- "What happened next?"
- "How did that make you feel?"

ENDING:
"Thank you so much, Grandpa Joe! 
Your family is going to love hearing this story. 
I'll call again next Wednesday at 10 AM. 
If you think of other stories before then, 
you can call me anytime at 1-800-FAMILY-STORY.
Take care!"

[CALL ENDS]

---

If NO / NOT AVAILABLE:
"No problem! Should I call back at a 
different time this week?"

[RESCHEDULE OR SKIP]
```

**Call Flow Logic:**
1. **Greeting:** Personalized with elder's name
2. **Permission:** Ask if they have time
3. **Prompt:** Single, specific question
4. **Recording:** 5-15 minutes with gentle prompts
5. **Closing:** Warm thanks + next call time + alternative call-in number

**Technical Details:**
- Voice: Natural, warm (not robotic)
- Caller ID: Family name + branded number
- Recording: Start after question, stop after thank you
- Transcription: Begins immediately
- Processing: AI titles story, tags people/events

---

### Elder Experience 2.2: Elder-Initiated Call (Optional)
```
[ELDER CALLS 1-800-FAMILY-STORY]

SYSTEM:
"Hello! Welcome to your family story line.
Please say your name."

ELDER: "Joe Johnson"

SYSTEM:
"Hi Grandpa Joe! Great to hear from you.
I have three options:

Say ONE to record a new story
Say TWO to hear a prompt question
Say THREE to hear your last story

What would you like?"

ELDER: "One"

SYSTEM:
"Perfect! Start telling your story whenever 
you're ready. When you're done, just hang up 
or say 'that's all' and I'll save it.
Go ahead!"

[RECORDS UNTIL ELDER HANGS UP OR SAYS "THAT'S ALL"]

SYSTEM:
"Got it! Your story has been saved and 
your family will be able to hear it soon.
Thank you, Grandpa Joe!"

[CALL ENDS]
```

**Benefits:**
- Elder can record anytime inspiration strikes
- No app needed
- Simple voice menu (3 options max)
- Immediate gratification ("story saved")

---

### Elder Experience 2.3: Elder App (Optional - for tech-comfortable elders)
```
┌─────────────────────────────────────┐
│                                     │
│  Hi Grandpa Joe 👋                  │
│                                     │
│                                     │
│  ┌───────────────────────────────┐  │
│  │                               │  │
│  │          ⏺                    │  │
│  │      (  RECORD  )             │  │
│  │   Tap to Record a Story       │  │
│  │                               │  │
│  └───────────────────────────────┘  │
│                                     │
│                                     │
│  📅 Next Call: Wednesday at 10 AM   │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  Today's Prompt:                    │
│  💭 "Tell me about your first job"  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │      Answer This Now          │  │
│  └───────────────────────────────┘  │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  Your Recent Stories (12):          │
│                                     │
│  🎤 My First Car        Dec 20     │
│  🎤 Meeting Grandma     Dec 13     │
│  🎤 The War Years       Dec 6      │
│                                     │
│         [See All Stories]           │
│                                     │
└─────────────────────────────────────┘
```

**Elements:**
- Large, prominent Record button (easy target)
- Next scheduled call reminder
- Today's prompt (if available)
- Recent stories list
- Minimal navigation (single screen focused on recording)

**Design Considerations:**
- Extra large text (18-22pt minimum)
- High contrast colors
- Simple, single-column layout
- No complex menus or gestures

---

## 3. Main App Screens

### Screen 3.1: Home - Stories Feed
```
┌─────────────────────────────────────┐
│ ≡  Family Stories          🔔(3) ⚙  │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 🆕 New Story from Grandpa Joe!  │ │
│ │ Tap to listen →                 │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ ╔═══════════════════════════╗   │ │
│ │ ║ [Grandpa Joe Photo]       ║   │ │
│ │ ║                           ║   │ │
│ │ ╚═══════════════════════════╝   │ │
│ │                                 │ │
│ │ 🎤 My First Car                 │ │
│ │ by Grandpa Joe                  │ │
│ │ 12 min · Dec 20, 2025           │ │
│ │                                 │ │
│ │ ▶ Play  💬 3 responses  ⋮      │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ ╔═══════════════════════════╗   │ │
│ │ ║ [Grandma Photo]           ║   │ │
│ │ ║                           ║   │ │
│ │ ╚═══════════════════════════╝   │ │
│ │                                 │ │
│ │ 🎤 The Day We Eloped            │ │
│ │ by Grandma Mary                 │ │
│ │ 8 min · Dec 13, 2025            │ │
│ │                                 │ │
│ │ ▶ Play  💬 5 responses  ⋮      │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ ╔═══════════════════════════╗   │ │
│ │ ║ [Dad Photo]               ║   │ │
│ │ ║                           ║   │ │
│ │ ╚═══════════════════════════╝   │ │
│ │                                 │ │
│ │ 🎤 Dad's Response: "I Remember  │ │
│ │    That Car Differently..."     │ │
│ │ by Dad · 3 min · Dec 21, 2025   │ │
│ │                                 │ │
│ │ ▶ Play  💬 Thread  ⋮            │ │
│ └─────────────────────────────────┘ │
│                                     │
│                                     │
│ ──────────────────────────────────  │
│ 🎙 Record                           │
└─────────────────────────────────────┘
```

**Elements:**
- **Header:**
  - Menu icon (hamburger) - left
  - "Family Stories" title - center
  - Notification bell with badge - right
  - Settings gear - far right
  
- **Alert Banner** (if new story):
  - Dismissible
  - Tappable to go directly to story

- **Story Cards** (repeated):
  - Cover image (photo of storyteller or AI-generated from content)
  - Story title (AI-generated)
  - Storyteller name
  - Duration + date
  - Play button (primary action)
  - Response count with icon
  - More menu (⋮)

- **Bottom Action:**
  - Large Record button (always accessible)

**Interactions:**
- Tap story card → Player screen (3.2)
- Tap Play button → Player screen (3.2)
- Tap "💬 X responses" → Thread view (4.3)
- Tap ⋮ → More menu (save, share, report)
- Tap 🔔 → Notifications screen
- Tap ⚙ → Settings screen
- Tap 🎙 Record → Recording screen (4.1)

**Feed Logic:**
- Newest stories first
- Highlight unplayed stories (visual indicator)
- Mix of original stories and thread responses
- Infinite scroll

---

### Screen 3.2: Story Player
```
┌─────────────────────────────────────┐
│ ←  My First Car              ⋮      │
│                                     │
│                                     │
│    ╔═════════════════════════╗      │
│    ║                         ║      │
│    ║  [Grandpa Joe Photo]    ║      │
│    ║     [or Album Art]      ║      │
│    ║                         ║      │
│    ╚═════════════════════════╝      │
│                                     │
│                                     │
│       My First Car                  │
│       by Grandpa Joe                │
│       Dec 20, 2025                  │
│                                     │
│                                     │
│  ●─────────────○──────────────○     │
│  0:00         6:24          12:48   │
│                                     │
│                                     │
│     ⏮   ◀◀   ▶️⏸   ▶▶   ⏭         │
│           [  Playing  ]             │
│                                     │
│                                     │
│  🔊 ───────○─────  1.0x  📱         │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  Transcript (optional)              │
│  "Well, it was a 1965 Mustang..."   │
│  [Expand to read full ▼]            │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  ┌─────────────────────────────────┐│
│  │  💬 See 3 Family Responses      ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │  🎤 Add Your Response            ││
│  └─────────────────────────────────┘│
│                                     │
│  ⭐ Favorite  ⬇ Download  📤 Share  │
│                                     │
└─────────────────────────────────────┘
```

**Elements:**
- **Header:**
  - Back button
  - Story title
  - More menu (⋮)

- **Cover Art:**
  - Large, square image
  - Storyteller photo or AI-generated visual

- **Story Info:**
  - Title
  - Author (storyteller)
  - Date

- **Playback Controls:**
  - Progress bar with timestamps (draggable)
  - Chapter markers (if multiple topics detected)
  - Previous track (if in playlist)
  - Skip back 15s
  - Play/Pause (large, central)
  - Skip forward 30s
  - Next track (if in playlist)

- **Audio Settings:**
  - Volume slider
  - Speed control (0.5x, 0.75x, 1.0x, 1.25x, 1.5x, 2.0x)
  - Output device (speaker/bluetooth)

- **Transcript:**
  - Collapsible
  - Auto-scroll with playback (if expanded)
  - Searchable (ctrl+F style)

- **Actions:**
  - See responses button (shows count)
  - Add response button (primary CTA)
  - Favorite, download, share (secondary)

**Interactions:**
- Tap Play/Pause → Toggle playback
- Drag progress bar → Seek to position
- Tap timestamp/marker → Jump to section
- Tap "See X Responses" → Thread view (4.3)
- Tap "Add Your Response" → Recording screen (4.1) with context
- Tap Favorite → Adds to favorites, animates
- Tap Download → Downloads for offline
- Tap Share → Share options (in-app or external)

**Audio Features:**
- Auto-pause on phone call/notification
- Resume where left off
- Background playback (lockscreen controls)
- AirPlay support

---

### Screen 3.3: Bottom Navigation
```
┌─────────────────────────────────────┐
│                                     │
│  [Main content area above]          │
│                                     │
│                                     │
│                                     │
│ ┌───────────────────────────────┐   │
│ │  🏠      🌳      🎙      💬    │   │
│ │ Stories  Tree   Record  Prompts│   │
│ └───────────────────────────────┘   │
└─────────────────────────────────────┘
```

**Tabs:**
1. **Stories (Home)** - Feed of all stories
2. **Tree** - Family tree visualization
3. **Record** - Quick record (modal)
4. **Prompts** - Daily prompts and threads

**Design:**
- Fixed bottom navigation
- Icons + labels
- Active state: Colored + bold
- Inactive: Gray
- Record button slightly elevated/emphasized

---

## 4. Story & Threading Screens

### Screen 4.1: Record Story/Response
```
┌─────────────────────────────────────┐
│  ✕                    Recording...  │
│                                     │
│                                     │
│  🎤                                 │
│                                     │
│                                     │
│  ●                                  │
│  (   REC   )                        │
│                                     │
│  [Pulsing red circle]               │
│                                     │
│                                     │
│       00:24                         │
│                                     │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │  💭 Prompt (if responding):     │ │
│ │  "Tell me about your first car" │ │
│ └─────────────────────────────────┘ │
│                                     │
│                                     │
│    [■]        [✓]                  │
│   Cancel     Done                   │
│                                     │
│                                     │
│  ⓘ Speak naturally. We'll clean    │
│     it up before sharing.           │
│                                     │
└─────────────────────────────────────┘
```

**Recording States:**

**Before Recording:**
```
│  ⏺                                  │
│  (   TAP TO RECORD   )              │
│  [Gray circle]                      │
│                                     │
│  💭 Responding to:                  │
│  "Grandpa's story about his car"    │
```

**While Recording:**
```
│  ⏸                                  │
│  (   PAUSE   )                      │
│  [Pulsing red circle]               │
│  Waveform animation                 │
│  00:24                              │
```

**After Recording:**
```
│  ▶                                  │
│  (   PLAY BACK   )                  │
│  [Play button]                      │
│  02:43                              │
│                                     │
│  [Re-record]  [✓ Keep]              │
```

**Elements:**
- Close button (X) - top left
- Recording status - top right
- Large record/pause button (center)
- Timer
- Context prompt (if responding to story)
- Cancel/Done buttons
- Helper text

**Interactions:**
- Tap ⏺ → Start recording (ask mic permission if needed)
- Tap ⏸ → Pause recording
- Tap ■ Cancel → Confirm discard
- Tap ✓ Done → Review screen (4.2)
- Long press record → Continuous recording mode

**Technical:**
- Max recording length: 15 minutes
- Warning at 1 minute remaining
- Auto-save draft every 30 seconds
- Background recording supported

---

### Screen 4.2: Review & Publish Recording
```
┌─────────────────────────────────────┐
│  ←                                  │
│                                     │
│       Review Your Story             │
│                                     │
│  ┌─────────────────────────────────┐│
│  │  ▶ Play Back    🎤 Re-record   ││
│  │                                 ││
│  │  02:43 recorded                 ││
│  └─────────────────────────────────┘│
│                                     │
│  AI suggested title:                │
│  ┌─────────────────────────────────┐│
│  │ Dad's Memory of the Mustang     ││
│  │ [Edit]                          ││
│  └─────────────────────────────────┘│
│                                     │
│  Who is this story about? (optional)│
│  ┌─────────────────────────────────┐│
│  │ [👤 Grandpa Joe] [+]            ││
│  └─────────────────────────────────┘│
│                                     │
│  Add a photo? (optional)            │
│  ┌─────────────────────────────────┐│
│  │  [📷 Add Photo]                 ││
│  └─────────────────────────────────┘│
│                                     │
│  Privacy:                           │
│  ● Share with all family            │
│  ○ Share with specific people       │
│  ○ Keep private for now             │
│                                     │
│  ┌───────────────────────────────┐  │
│  │      Publish Story            │  │
│  └───────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

**Elements:**
- Play back button
- Re-record button (goes back to 4.1)
- Duration display
- Title (AI-generated, editable)
- Tag people mentioned (autocomplete from family list)
- Add photo (optional)
- Privacy controls
- Publish button (primary CTA)

**Interactions:**
- Tap Play Back → Plays recording
- Tap Re-record → Back to recording screen
- Tap Edit title → Keyboard opens
- Tap + on people → Search family members
- Tap Add Photo → Camera/library picker
- Select privacy option → Radio button updates
- Tap Publish → Publishing animation → Success screen (4.2b)

---

### Screen 4.2b: Publishing Success
```
┌─────────────────────────────────────┐
│                                     │
│              ✅                     │
│                                     │
│       Story Published!              │
│                                     │
│  Your family will be notified.      │
│                                     │
│                                     │
│  ┌───────────────────────────────┐  │
│  │     Back to Stories           │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │     Record Another            │  │
│  └───────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

**Elements:**
- Success checkmark animation
- Confirmation message
- Next action buttons

**Interactions:**
- Auto-dismiss after 3 seconds → Returns to home
- Tap "Back to Stories" → Home feed
- Tap "Record Another" → Recording screen (4.1)

---

### Screen 4.3: Story Thread View
```
┌─────────────────────────────────────┐
│  ←  Thread: My First Car            │
│                                     │
│  ┌─────────────────────────────────┐│
│  │ ╔═══════╗                       ││
│  │ ║[👴]   ║  Grandpa Joe          ││
│  │ ╚═══════╝  Dec 20, 2025         ││
│  │                                 ││
│  │ 🎤 My First Car (Original)      ││
│  │ 12 min                          ││
│  │                                 ││
│  │ ▶ Play                          ││
│  │                                 ││
│  │ "It was a 1965 Mustang..."      ││
│  └─────────────────────────────────┘│
│         │                           │
│         └──────────────┐            │
│  ┌─────────────────────────────────┐│
│  │ ╔═══════╗                       ││
│  │ ║[👨]   ║  Dad                  ││
│  │ ╚═══════╝  Dec 21, 2025         ││
│  │                                 ││
│  │ 🎤 I Remember That Car          ││
│  │    Differently...               ││
│  │ 3 min                           ││
│  │                                 ││
│  │ ▶ Play  💬 Reply                ││
│  │                                 ││
│  │ "Actually, it was a '67..."     ││
│  └─────────────────────────────────┘│
│         │                           │
│         └──────────────┐            │
│  ┌─────────────────────────────────┐│
│  │ ╔═══════╗                       ││
│  │ ║[👩]   ║  Aunt Sarah           ││
│  │ ╚═══════╝  Dec 21, 2025         ││
│  │                                 ││
│  │ 🎤 You're Both Wrong!           ││
│  │ 2 min                           ││
│  │                                 ││
│  │ ▶ Play  💬 Reply                ││
│  │                                 ││
│  │ "I have photos that prove..."   ││
│  └─────────────────────────────────┘│
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  🎤 Add Your Perspective       │  │
│  └───────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

**Elements:**
- Thread title (from original story)
- Original story card (highlighted/larger)
- Response cards (nested with visual connectors)
- Each card shows:
  - Avatar
  - Name and date
  - Response title
  - Duration
  - Play button
  - Reply button (for nested threads)
  - Transcript preview
- Visual tree structure (lines showing relationships)
- Add response button (bottom, sticky)

**Interactions:**
- Tap Play on any card → Mini player (inline) or full player
- Tap Reply → Recording screen with context
- Tap "Add Your Perspective" → Recording screen
- Scroll to see all responses
- Long press card → More options (share, report, etc.)

**Threading Logic:**
- Up to 3 levels deep (Original → Response → Reply)
- After 3 levels, "replies" become separate threads
- Visual indicators show depth

---

### Screen 4.4: Prompt Center
```
┌─────────────────────────────────────┐
│ ←  Today's Prompts          📅      │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 💭 Featured Prompt              │ │
│ │                                 │ │
│ │ Did Grandpa really leave Dad    │ │
│ │ at the bus station?             │ │
│ │                                 │ │
│ │ ┌─────────────────────────────┐ │ │
│ │ │ 👴 Grandpa says: YES         │ │ │
│ │ │ ▶ 4 min · 3 responses        │ │ │
│ │ └─────────────────────────────┘ │ │
│ │                                 │ │
│ │ [🎤 Share Your Version]         │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ─────────────────────────────────   │
│                                     │
│ Open Questions for You:             │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ ❓ Mom hasn't responded yet:    │ │
│ │                                 │ │
│ │ "What was Mom's first job?"     │ │
│ │                                 │ │
│ │ [Ask Mom] [I'll Answer]         │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 🔥 Family wants to know:        │ │
│ │                                 │ │
│ │ "Who was the favorite child?"   │ │
│ │                                 │ │
│ │ 👴👵 Grandparents answered      │ │
│ │ ⏰ Waiting on 3 more            │ │
│ │                                 │ │
│ │ [🎤 Your Answer]                │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ─────────────────────────────────   │
│                                     │
│ Suggested Prompts:                  │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 💡 Ask Grandpa:                 │ │
│ │ "What was your favorite        │ │
│ │  childhood memory?"             │ │
│ │                                 │ │
│ │ [Schedule for Next Call]        │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 💡 Family Drama:                │ │
│ │ "What really happened at       │ │
│ │  Uncle Bob's wedding?"          │ │
│ │                                 │ │
│ │ [Ask Family]                    │ │
│ └─────────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

**Elements:**
- **Featured Prompt (top):**
  - Big, card-style presentation
  - Shows current responses
  - Prominent record button

- **Open Questions for You:**
  - Personalized prompts
  - Shows who has/hasn't responded
  - Social pressure indicators

- **Suggested Prompts:**
  - AI-generated based on family history
  - Curated by themes
  - Easy to schedule or activate

**Interactions:**
- Tap any prompt → View existing responses (if any) + record option
- Tap "Share Your Version" → Recording screen with prompt
- Tap "Ask [Person]" → Schedules question for their next call
- Tap "I'll Answer" → Recording screen
- Tap "Schedule for Next Call" → Added to elder's call queue
- Tap "Ask Family" → Sends notification to all

**Prompt Types:**
1. **Reaction prompts:** "Did this really happen?"
2. **Perspective prompts:** "How do YOU remember this?"
3. **Fill-in-the-blank:** "What's YOUR story about [topic]?"
4. **Debate prompts:** "Who was the favorite?" (encourages discussion)

---

## 5. Family Tree Screens

### Screen 5.1: Family Tree Visualization
```
┌─────────────────────────────────────┐
│ ←  Johnson Family Tree      [?] ⚙   │
│                                     │
│  [Pinch to zoom, drag to pan]       │
│                                     │
│         Grandpa Joe ─ Grandma Mary  │
│         👴 (24)         👵 (18)     │
│         ╱          │          ╲     │
│       ╱            │            ╲   │
│     Dad          Mom          Aunt  │
│     👨 (12)      👩 (8)       👩 (6)│
│      │            │                 │
│   ┌──┴──┐      ┌──┴──┐             │
│  You  Sister  Cousin  Cousin2       │
│  👤(5) 👧(3)   👦(2)   👶(0)        │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  Legend:                            │
│  Number = Stories contributed       │
│  💚 Green = Active (stories this    │
│            month)                   │
│  🟡 Yellow = Inactive               │
│  ⚪ Gray = Never contributed        │
│                                     │
│  Tap any person to see their        │
│  stories and details                │
│                                     │
└─────────────────────────────────────┘
```

**Elements:**
- Interactive tree diagram
- Each person represented by:
  - Avatar (photo or icon)
  - Name
  - Story count badge
  - Status color (active/inactive/never)
- Relationship lines connecting family
- Zoom/pan controls
- Legend explaining colors
- Help icon (explains how to use)

**Interactions:**
- Tap person node → Person detail screen (5.2)
- Pinch to zoom in/out
- Drag to pan around tree
- Two-finger rotate (optional)
- Tap + icon → Add family member

**Visual States:**
- **Active (green):** Contributed story this month
- **Inactive (yellow):** Has stories but not recent
- **Never (gray):** Never contributed
- **Invited (dotted outline):** Invited but not joined
- **Elder (gold ring):** Designated elder with scheduled calls

---

### Screen 5.2: Person Detail
```
┌─────────────────────────────────────┐
│  ←  Grandpa Joe                  ⋮  │
│                                     │
│         ╔═══════════╗               │
│         ║           ║               │
│         ║  [Photo]  ║               │
│         ║           ║               │
│         ╚═══════════╝               │
│                                     │
│         Joseph "Joe" Johnson        │
│         Grandfather                 │
│                                     │
│  ┌─────────────────────────────────┐│
│  │ 📊  24 stories shared           ││
│  │ 🎤  Last story: 2 days ago      ││
│  │ 📅  Next call: Wed 10 AM        ││
│  └─────────────────────────────────┘│
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  His Stories:                       │
│                                     │
│  🎤 My First Car         Dec 20     │
│     12 min · 3 responses            │
│                                     │
│  🎤 Meeting Grandma      Dec 13     │
│     8 min · 5 responses             │
│                                     │
│  🎤 The War Years        Dec 6      │
│     15 min · 2 responses            │
│                                     │
│         [See All 24 Stories]        │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  Stories About Him: (3)             │
│                                     │
│  🎤 Dad's Response: "I Remember..." │
│     by Dad · 3 min                  │
│                                     │
│         [See All]                   │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  💬 Send Him a Prompt          │  │
│  └───────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

**Elements:**
- Profile photo (large)
- Name and relationship
- Stats card:
  - Total stories
  - Last activity
  - Next scheduled call (if elder)
- List of their stories
- List of stories about them
- Send prompt button

**Interactions:**
- Tap story → Player screen (3.2)
- Tap "See All X Stories" → Filtered story feed
- Tap "Send Him a Prompt" → Prompt composer
- Tap ⋮ → Edit profile, manage calls (if admin)

---

### Screen 5.3: Family Stats (Engagement Dashboard)
```
┌─────────────────────────────────────┐
│  ←  Family Progress                 │
│                                     │
│  December 2025                      │
│                                     │
│  ┌─────────────────────────────────┐│
│  │ 🎉 12 stories this month        ││
│  │ 📈 Up from 8 last month (+50%)  ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │ Family Participation            ││
│  │                                 ││
│  │ 👴 Grandpa Joe     ████████ 24  ││
│  │ 👵 Grandma Mary    ██████   18  ││
│  │ 👨 Dad             ████     12  ││
│  │ 👩 Mom             ███       8  ││
│  │ 👩 Aunt Sarah      ██        6  ││
│  │ 👤 You             ██        5  ││
│  │ 👧 Sister          █         3  ││
│  │ 👦 Cousin          █         2  ││
│  │                                 ││
│  │ ⚪ 2 members haven't shared yet ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │ Most Active Thread 🔥           ││
│  │                                 ││
│  │ "Who was the favorite child?"   ││
│  │ 12 responses                    ││
│  │                                 ││
│  │ [View Thread]                   ││
│  └─────────────────────────────────┘│
│                                     │
│  Milestones:                        │
│  ✅ 50 total stories                │
│  ✅ 8 family members active         │
│  🔒 100 stories (52 to go)          │
│  🔒 3 generations active (1 to go)  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  Invite More Family            │  │
│  └───────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

**Elements:**
- Monthly summary
- Participation chart (horizontal bars)
- Highlights (most active thread, etc.)
- Milestones (gamification)
- Invite button

**Purpose:**
- Show family engagement health
- Create social pressure (who's contributing, who's not)
- Celebrate milestones
- Encourage invites

---

## 6. Profile & Settings

### Screen 6.1: User Profile
```
┌─────────────────────────────────────┐
│  ←  Your Profile                 ⚙  │
│                                     │
│         ╔═══════════╗               │
│         ║           ║               │
│         ║  [Photo]  ║               │
│         ║           ║               │
│         ╚═══════════╝               │
│         [Edit Photo]                │
│                                     │
│         Your Name                   │
│         Son                         │
│                                     │
│  ┌─────────────────────────────────┐│
│  │ 📊 Your Stats                   ││
│  │                                 ││
│  │ 5 stories shared                ││
│  │ 12 responses given              ││
│  │ Member since Dec 2025           ││
│  └─────────────────────────────────┘│
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  Your Stories (5):                  │
│                                     │
│  🎤 My Memory of the Mustang        │
│     3 min · 2 responses             │
│                                     │
│  🎤 Grandpa's Advice to Me          │
│     5 min · 4 responses             │
│                                     │
│         [See All]                   │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  Edit Profile                  │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  Notification Settings         │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  Privacy Settings              │  │
│  └───────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

**Elements:**
- Profile photo (editable)
- Name and relationship
- Stats summary
- Recent stories
- Settings links

---

### Screen 6.2: Notification Settings
```
┌─────────────────────────────────────┐
│  ←  Notification Settings           │
│                                     │
│  Notifications                      │
│  [●────────] On                     │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  New Stories                        │
│  ┌─────────────────────────────────┐│
│  │ New story from anyone     [●]   ││
│  │ New story from elders     [●]   ││
│  │ New response to my story  [●]   ││
│  └─────────────────────────────────┘│
│                                     │
│  Prompts                            │
│  ┌─────────────────────────────────┐│
│  │ Daily prompts             [●]   ││
│  │ When: 9:00 AM             [>]   ││
│  │                                 ││
│  │ Thread nudges (when someone     ││
│  │ responds before you)      [●]   ││
│  │                                 ││
│  │ Inactivity reminders      [○]   ││
│  │ (after 7 days)                  ││
│  └─────────────────────────────────┘│
│                                     │
│  Family Activity                    │
│  ┌─────────────────────────────────┐│
│  │ Weekly family digest      [●]   ││
│  │ New family members joined [●]   ││
│  │ Milestones reached        [●]   ││
│  └─────────────────────────────────┘│
│                                     │
│  Delivery                           │
│  ┌─────────────────────────────────┐│
│  │ Push notifications        [●]   ││
│  │ Email                     [●]   ││
│  │ SMS                       [○]   ││
│  └─────────────────────────────────┘│
│                                     │
└─────────────────────────────────────┘
```

**Elements:**
- Master notification toggle
- Categorized notification types
- Toggles for each type
- Time pickers for scheduled notifications
- Delivery method toggles

**Key Settings:**
- **New Stories:** When to be notified of new content
- **Prompts:** Daily prompt timing and nudges
- **Family Activity:** Digests and updates
- **Delivery:** Push, email, SMS preferences

---

### Screen 6.3: Family Settings (Admin Only)
```
┌─────────────────────────────────────┐
│  ←  Family Settings                 │
│                                     │
│  The Johnson Family                 │
│  Admin: You                         │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  Family Members (10)                │
│                                     │
│  👴 Grandpa Joe          Elder      │
│     [Edit] [Remove]                 │
│                                     │
│  👵 Grandma Mary         Elder      │
│     [Edit] [Remove]                 │
│                                     │
│  👨 Dad                  Member     │
│     [Edit] [Remove]                 │
│                                     │
│  👩 Mom                  Admin      │
│     [Edit] [Remove]                 │
│                                     │
│  [+ Add Family Member]              │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  Elder Call Schedule                │
│                                     │
│  👴 Grandpa Joe                     │
│     Wednesdays at 10:00 AM EST      │
│     [Edit Schedule]                 │
│                                     │
│  👵 Grandma Mary                    │
│     Fridays at 2:00 PM EST          │
│     [Edit Schedule]                 │
│                                     │
│  [+ Add Another Elder]              │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  Subscription                       │
│  Medium Family Plan - $34.99/mo     │
│  10 members · 2 elders              │
│  [Manage Subscription]              │
│                                     │
│  Privacy                            │
│  [Content Moderation Settings]      │
│  [Data & Export]                    │
│                                     │
└─────────────────────────────────────┘
```

**Elements:**
- Family name and admin
- Family member list with roles
- Edit/remove buttons (for admins)
- Add member button
- Elder call schedules
- Subscription details
- Privacy settings links

**Admin Actions:**
- Add/remove family members
- Assign roles (Elder, Admin, Member)
- Edit call schedules
- Manage subscription
- Export all family data
- Content moderation settings

---

## 7. Admin Dashboard (Web)

### Screen 7.1: Dashboard Overview (Web)
```
┌─────────────────────────────────────────────────────────────┐
│  [Logo] The Johnson Family                    [You ▼]  ⚙   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐  │
│  │    24     │ │    10     │ │    3      │ │   82%     │  │
│  │  Stories  │ │  Members  │ │  Pending  │ │  Active   │  │
│  └───────────┘ └───────────┘ └───────────┘ └───────────┘  │
│                                                             │
│  ┌──────────────────────────────┐ ┌────────────────────┐   │
│  │ Recent Activity              │ │ Upcoming Calls     │   │
│  │                              │ │                    │   │
│  │ 🎤 Dad responded to story    │ │ 📅 Wed 10 AM       │   │
│  │    2 hours ago               │ │    Grandpa Joe     │   │
│  │                              │ │                    │   │
│  │ 🎤 Grandpa Joe shared        │ │ 📅 Fri 2 PM        │   │
│  │    "My First Car"            │ │    Grandma Mary    │   │
│  │    1 day ago                 │ │                    │   │
│  │                              │ │ [Edit Schedules]   │   │
│  │ ✉️  Sister joined            │ └────────────────────┘   │
│  │    2 days ago                │                          │
│  │                              │ ┌────────────────────┐   │
│  │ [View All Activity]          │ │ Action Needed      │   │
│  └──────────────────────────────┘ │                    │   │
│                                   │ ⚠️  2 stories need │   │
│  ┌──────────────────────────────┐ │     review         │   │
│  │ Stories Pending Review (2)   │ │                    │   │
│  │                              │ │ ⚠️  3 invites      │   │
│  │ 🎤 Dad's Response: Car Story │ │     pending        │   │
│  │    [✓ Approve] [✕ Reject]   │ │                    │   │
│  │                              │ │ [Review Now]       │   │
│  │ 🎤 Sister: Wedding Drama     │ └────────────────────┘   │
│  │    [✓ Approve] [✕ Reject]   │                          │
│  │                              │                          │
│  └──────────────────────────────┘                          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Key Sections:**
- **Top Metrics:** Stories, members, pending items, activity %
- **Recent Activity:** Feed of latest actions
- **Upcoming Calls:** Schedule overview
- **Pending Review:** Stories awaiting approval
- **Action Needed:** Alerts and tasks

---

### Screen 7.2: Story Management (Web)
```
┌─────────────────────────────────────────────────────────────┐
│  Stories                  [+ Add Story] [🔍 Search] [Filter]│
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  All (24) | Published (21) | Pending (2) | Drafts (1)      │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ 🎤 My First Car                               [⋮]    │  │
│  │ by Grandpa Joe · Dec 20, 2025 · 12 min                │  │
│  │ 👁 12 listens · 💬 3 responses                        │  │
│  │                                                        │  │
│  │ [▶ Play] [View Thread] [Edit] [Delete]                │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ 🎤 Dad's Response: "I Remember That Car..."   ⏸ PEND │  │
│  │ by Dad · Dec 21, 2025 · 3 min                          │  │
│  │                                                        │  │
│  │ [▶ Play] [✓ Approve] [✏️ Edit] [✕ Reject]             │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ 🎤 The Day We Eloped                          [⋮]    │  │
│  │ by Grandma Mary · Dec 13, 2025 · 8 min                 │  │
│  │ 👁 18 listens · 💬 5 responses                        │  │
│  │                                                        │  │
│  │ [▶ Play] [View Thread] [Edit] [Delete]                │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                             │
│  [Load More]                                     Page 1 of 3│
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Features:**
- Filter by status (All, Published, Pending, Drafts)
- Search stories
- Bulk actions
- Individual story actions:
  - Play/preview
  - Approve/reject (if pending)
  - Edit title, description, tags
  - Delete (with confirmation)
  - View thread
  - Download audio

---

### Screen 7.3: Family Member Management (Web)
```
┌─────────────────────────────────────────────────────────────┐
│  Family Members            [+ Invite Member] [Export List]  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  All (10) | Active (8) | Inactive (1) | Invited (1)         │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ 👴 Grandpa Joe                          ELDER    [⋮] │  │
│  │ joseph.johnson@email.com                              │  │
│  │ +1 (555) 123-4567                                     │  │
│  │                                                        │  │
│  │ 📊 24 stories · Last active: 2 days ago                │  │
│  │ 📅 Next call: Wed Dec 27 at 10:00 AM EST              │  │
│  │                                                        │  │
│  │ [Edit Profile] [Edit Schedule] [Send Message]          │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ 👨 Dad                                  MEMBER   [⋮] │  │
│  │ dad@email.com                                          │  │
│  │ +1 (555) 234-5678                                     │  │
│  │                                                        │  │
│  │ 📊 12 stories · Last active: 3 hours ago               │  │
│  │                                                        │  │
│  │ [Edit Profile] [Make Admin] [Send Message]             │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ 👦 Cousin Jake                      INVITED      [⋮] │  │
│  │ jake@email.com                                         │  │
│  │                                                        │  │
│  │ ✉️  Invited 5 days ago · Not yet joined                │  │
│  │                                                        │  │
│  │ [Resend Invite] [Cancel Invite]                        │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Features:**
- View all family members
- Filter by status
- Member details:
  - Contact info
  - Role (Elder, Admin, Member)
  - Activity stats
  - Last active
  - Call schedule (if elder)
- Actions:
  - Edit profile
  - Change role
  - Edit call schedule
  - Send message/prompt
  - Remove member
  - Resend/cancel invite

---

## Additional Screens (Brief)

### Notifications Screen
- List of all notifications
- Filter by type (New Stories, Prompts, Responses, etc.)
- Mark as read/unread
- Clear all

### Search Screen
- Search bar at top
- Recent searches
- Suggested searches
- Results: Stories, people, prompts
- Filters: Date range, person, keyword

### First-Time Experience (FTE) Tooltips
- After setup, show brief tooltips:
  - "Tap here to record your first story"
  - "This is your family tree"
  - "Check prompts here daily"
- Progressive disclosure (not all at once)

### Empty States
- **No stories yet:** "Your first story is being recorded! Check back Wednesday."
- **No prompts:** "Check back tomorrow for new prompts"
- **No responses:** "Be the first to respond!"

### Error States
- Recording failed: "Couldn't save recording. Try again?"
- Network error: "No connection. We'll sync when you're back online."
- Permission denied: "We need microphone access to record stories"

---

## Responsive Design Notes

### Mobile (Primary Platform)
- Single column layouts
- Bottom navigation for primary actions
- Large tap targets (min 44x44pt)
- Thumb-friendly zones (important actions at bottom)

### Tablet
- Two-column layouts where appropriate
- Side navigation instead of bottom tabs
- Utilize extra space for thread views (side-by-side)

### Web Dashboard
- Full desktop layout
- Table views for lists
- Bulk actions
- Advanced filtering and search
- Multi-column layouts

---

## Accessibility

### Requirements
- **WCAG 2.1 AA compliance**
- VoiceOver/TalkBack support
- Dynamic type (text scaling)
- High contrast mode
- Reduce motion option
- Haptic feedback for key actions

### Elder-Specific
- Extra-large text option (18-24pt base)
- Simplified mode toggle (hides advanced features)
- Voice navigation support
- Large buttons (min 60x60pt for elders)

---

**End of Wireframes Document**

*This is a living document and screens may be updated based on user feedback and testing.*
