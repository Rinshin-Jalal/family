# User Flows & Journey Maps
# Family Memory App

**Version:** 1.0  
**Last Updated:** December 20, 2025

---

## Table of Contents

1. [Flow Notation Guide](#flow-notation-guide)
2. [Onboarding Flows](#onboarding-flows)
3. [Elder Experience Flows](#elder-experience-flows)
4. [Story Consumption Flows](#story-consumption-flows)
5. [Story Creation & Threading Flows](#story-creation--threading-flows)
6. [Engagement & Prompt Flows](#engagement--prompt-flows)
7. [Family Tree Flows](#family-tree-flows)
8. [Admin & Management Flows](#admin--management-flows)
9. [Edge Cases & Error Flows](#edge-cases--error-flows)

---

## Flow Notation Guide

```
[Screen Name] - Rectangular box represents a screen
    ↓
(User Action) - Parentheses represent user interaction
    ↓
{System Action} - Curly braces represent automated system action
    ↓
<Decision Point> - Angle brackets represent conditional logic
    ↓
→ Path continues to the right
↓ Path continues down
┌─ Path branches
└─ Path rejoins
```

---

## 1. Onboarding Flows

### Flow 1.1: Complete Onboarding (Happy Path)

```
START
  ↓
[Landing Screen]
  ↓
(Tap "Get Started")
  ↓
[Account Creation]
  ↓
(Fill: Name, Email, Phone, Password)
  ↓
{Validate input}
  ↓
<Valid?>
  ├─ NO → [Show error message] → (Fix errors) → Loop back
  └─ YES ↓
(Tap "Continue")
  ↓
{Create account}
{Send verification email/SMS}
  ↓
[Family Setup]
  ↓
(Enter family name: "The Johnsons")
  ↓
(Tap "Continue")
  ↓
[Add Elder Screen]
  ↓
(Upload photo - optional)
(Enter name: "Grandpa Joe")
(Select relationship: "Grandfather")
(Enter phone: "+1 555-123-4567")
  ↓
<All required fields filled?>
  ├─ NO → [Continue button disabled]
  └─ YES ↓
(Tap "Continue")
  ↓
{Validate phone number}
  ↓
<Phone valid?>
  ├─ NO → [Show error] → (Fix) → Loop back
  └─ YES ↓
[Schedule Calls]
  ↓
(Select day: "Wednesday")
(Select time: "10:00 AM")
(Select timezone: "EST")
  ↓
(Tap "Schedule First Call")
  ↓
{Create elder profile}
{Schedule first call in system}
{Add to call queue}
  ↓
[Invite Family]
  ↓
(Enter email/phone for Mom, Sister, Brother)
(Tap "Add" for each)
  ↓
{Validate each contact}
  ↓
<At least 3 added?>
  ├─ NO → [Button says "Add at least 3 (recommended)"]
  └─ YES ↓
(Tap "Send Invites & Finish")
  ↓
{Send invitation emails/SMS}
{Create member profiles (pending)}
{Set onboarding complete flag}
  ↓
[Setup Complete Screen]
  ↓
{Show next call date}
{Show success animation}
  ↓
(Tap "Go to Family Stories")
  ↓
[Home Screen - Empty State]
  ↓
{Show welcome message}
{Show "First story coming Wednesday"}
{Show tutorial tooltips}
  ↓
END
```

**Success Criteria:**
- Account created ✓
- Family named ✓
- 1+ elder added with phone ✓
- First call scheduled ✓
- 3+ family members invited ✓

**Time Estimate:** 3-5 minutes

---

### Flow 1.2: Skip Invites Path

```
[Invite Family Screen]
  ↓
(No one added yet)
  ↓
(Tap "Skip for now")
  ↓
{Show confirmation modal}
  ↓
[Modal: "You can invite family later"]
[Button: "Got it" | "Go Back"]
  ↓
<User choice?>
  ├─ "Go Back" → [Return to Invite Family]
  └─ "Got it" ↓
{Set flag: needs_invites = true}
{Schedule reminder notification (24 hours)}
  ↓
[Setup Complete Screen]
  ↓
(Continue to app)
  ↓
[Home Screen]
  ↓
{Show banner: "Invite family to share the experience"}
  ↓
END
```

**Follow-up Actions:**
- 24-hour reminder: "Stories are better with family. Invite yours now?"
- After first story: "Grandpa's story is ready! Who should hear it?"

---

### Flow 1.3: Multiple Elders Path

```
[Add Elder Screen]
  ↓
(Complete first elder: Grandpa Joe)
  ↓
(Tap "Continue")
  ↓
[Schedule Calls for Grandpa Joe]
  ↓
(Schedule completed)
  ↓
{Show modal: "Want to add another elder?"}
[Button: "Add Another Elder" | "Continue"]
  ↓
<User choice?>
  ├─ "Continue" → [Invite Family Screen]
  └─ "Add Another Elder" ↓
[Add Elder Screen - Round 2]
  ↓
(Complete second elder: Grandma Mary)
  ↓
(Tap "Continue")
  ↓
[Schedule Calls for Grandma Mary]
  ↓
{Ensure different day/time than first elder}
  ↓
(Schedule completed)
  ↓
{Show modal again or continue to invites}
  ↓
[Invite Family Screen]
  ↓
(Continue flow...)
  ↓
END
```

**Business Logic:**
- Free tier: 1 elder max
- Small/Medium tier: 2 elders max
- Large tier: 3 elders max
- Extended tier: 5 elders max
- Upsell prompt if limit reached

---

## 2. Elder Experience Flows

### Flow 2.1: Scheduled Automated Call (Success Path)

```
{System: Call time reached}
  ↓
{Initiate call to elder's phone}
{Set caller ID: Family name + photo}
  ↓
[Elder's Phone Rings]
  ↓
<Elder answers?>
  ├─ NO → {Mark as missed} → {Schedule retry in 24 hours} → {Notify admin} → END
  └─ YES ↓
{Play greeting}
"Hi Grandpa Joe! This is your Johnson Family story keeper."
  ↓
{Ask permission}
"Do you have about 10 minutes to share a story today?"
  ↓
<Elder responds?>
  ├─ NO / "Call back later" → {Ask for reschedule} → (Elder chooses time) → {Schedule new call} → END
  ├─ NO / Silence → {Repeat question} → <Still no response?> → {End call politely} → END
  └─ YES ↓
{Play prompt}
"Wonderful! Today's question is: Tell me about your first car."
  ↓
{Start recording}
{Set timer: 15 min max}
  ↓
[Elder speaks]
  ↓
<Recording status?>
  ├─ Silence for 30s → {Play gentle prompt: "Tell me more..."} → (Continue)
  ├─ Silence for 60s → {Play: "What happened next?"} → (Continue)
  ├─ 15 min reached → {Play: "That's wonderful. Let's wrap up."} → Jump to ending
  └─ Elder says "That's all" / natural ending detected ↓
{Stop recording}
{Play thank you}
"Thank you, Grandpa Joe! Your family will love this story."
  ↓
{Inform next call}
"I'll call again next Wednesday at 10 AM."
  ↓
{Remind about call-in number}
"If you think of other stories, call 1-800-FAMILY-STORY anytime."
  ↓
{End call}
  ↓
{Upload recording to server}
{Start transcription (AI)}
{Notify admin: "New story from Grandpa Joe - pending review"}
  ↓
<Processing complete?>
  ↓
{Generate title (AI)}
{Extract keywords, people, events}
{Create story card}
{Set status: Pending Review}
  ↓
{Send notification to admin}
  ↓
END (Admin flow begins at Flow 8.2)
```

**Success Criteria:**
- Call completed ✓
- Recording captured ✓
- Transcription processed ✓
- Admin notified ✓

**Average Duration:** 8-12 minutes

---

### Flow 2.2: Elder-Initiated Call (Elder Calls In)

```
{Elder dials 1-800-FAMILY-STORY}
  ↓
{System picks up}
{Play greeting}
"Hello! Welcome to your family story line."
  ↓
{Request identification}
"Please say your name."
  ↓
[Elder speaks name: "Joe Johnson"]
  ↓
{Speech-to-text recognition}
{Match against family database}
  ↓
<Match found?>
  ├─ NO → {Ask to spell name} → {Manual match} → <Still no match?> → {Transfer to support} → END
  └─ YES ↓
{Personalized greeting}
"Hi Grandpa Joe! Great to hear from you."
  ↓
{Present menu}
"I have three options:
 Say ONE to record a new story
 Say TWO to hear a prompt question  
 Say THREE to hear your last story"
  ↓
<Elder's choice?>
  ├─ "One" / "Record" ↓
  │   {Start recording mode}
  │   "Perfect! Start whenever you're ready. Say 'that's all' when done."
  │   {Record audio}
  │   [Elder speaks]
  │   <Elder says "that's all" or hangs up?>
  │   {Stop recording}
  │   {Upload and process}
  │   {Confirm: "Story saved!"}
  │   END
  │
  ├─ "Two" / "Prompt" ↓
  │   {Fetch next prompt from queue}
  │   {Play prompt: "Tell me about your first job"}
  │   "Would you like to answer this now?"
  │   <Elder's choice?>
  │   ├─ YES → {Start recording} → (Same as "One" path)
  │   └─ NO → {Return to menu}
  │
  └─ "Three" / "Last story" ↓
      {Fetch last recorded story}
      {Play back audio}
      [Elder listens]
      {After playback: "Would you like to record something else?"}
      <Elder's choice?>
      ├─ YES → {Return to menu}
      └─ NO → {Thank and end}
  ↓
END
```

**Benefits:**
- Elder can record anytime (not just scheduled calls)
- No app required
- Simple 3-option menu
- Immediate feedback

---

### Flow 2.3: Elder Uses Mobile App (Optional)

```
{Elder opens app}
  ↓
[Elder Home Screen]
{Shows: Large record button, next call time, today's prompt}
  ↓
<Elder's action?>
  ├─ Tap "Record" button ↓
  │   [Recording Screen]
  │   (Hold to record)
  │   {Start recording}
  │   [Elder speaks]
  │   (Release to stop)
  │   {Stop recording}
  │   [Playback option]
  │   <Keep or re-record?>
  │   ├─ Re-record → Loop back
  │   └─ Keep → {Upload} → {Process} → [Success]
  │   END
  │
  ├─ Tap "Answer This Now" (prompt) ↓
  │   {Load prompt context}
  │   [Recording Screen with prompt displayed]
  │   (Same recording flow as above)
  │   END
  │
  └─ Tap a past story ↓
      [Story Player]
      {Play their own story}
      [Listen]
      {See family responses}
      END
```

**Design Note:**
- Elder app is simplified: Fewer options, larger text, simpler navigation
- Optional feature (not required)
- Most elders will use phone call method

---

## 3. Story Consumption Flows

### Flow 3.1: Listen to New Story (Push Notification Entry)

```
{System: New story published}
  ↓
{Send push notification to all family}
"🎤 New story from Grandpa Joe: 'My First Car'"
  ↓
[User's phone shows notification]
  ↓
<User action?>
  ├─ Dismiss → {Mark as unread} → END (story remains in feed)
  └─ Tap notification ↓
{Open app}
{Navigate to story}
  ↓
[Story Player Screen]
{Auto-play ON}
  ↓
{Start playback}
  ↓
[User listens]
  ↓
<Playback status?>
  ├─ User pauses → {Remember position} → <Resume later?> → {Resume from position}
  ├─ User skips forward/back → {Update position}
  ├─ User switches to other app → {Continue background playback}
  ├─ User closes app → {Save position} → END
  └─ Story finishes ↓
{Mark story as "played"}
{Show end-of-story screen}
  ↓
[End-of-story actions]
"What did you think?"
[Button: ❤️ Love it] [Button: 🤔 Interesting] [Button: 😂 Funny]
[Button: 🎤 Add Response] [Button: ⭐ Favorite]
  ↓
<User action?>
  ├─ Tap reaction → {Record reaction} → {Show: "Grandpa will love seeing this"} → END
  ├─ Tap Add Response → [Recording Screen] → (Flow 4.2)
  ├─ Tap Favorite → {Add to favorites} → {Animate heart} → END
  └─ Do nothing → {Show next suggested story} → <Play next?> → Loop or END
```

**Engagement Hooks:**
- Auto-play next story (if user doesn't dismiss)
- Reaction buttons (low-effort engagement)
- Immediate response option (high-effort engagement)

---

### Flow 3.2: Browse Feed and Discover Story

```
[User opens app]
  ↓
[Home - Stories Feed]
{Load stories: Newest first}
{Highlight unplayed stories}
  ↓
<User scrolls feed>
  ↓
[Sees story card: "The Day We Eloped" by Grandma]
  ↓
(Tap story card)
  ↓
[Story Player Screen]
{Load story metadata}
{Load audio file}
  ↓
<Auto-play enabled?>
  ├─ YES → {Start playback immediately}
  └─ NO → {Show play button} → (User taps play)
  ↓
[Playback begins]
(User listens - same as Flow 3.1)
  ↓
<User wants to see responses?>
  ↓
(Tap "See X Responses" button)
  ↓
[Story Thread View]
{Load all responses}
{Show nested thread structure}
  ↓
<User action?>
  ├─ Play a response → {Open inline mini-player} → [Plays response]
  ├─ Tap "Add Your Perspective" → [Recording Screen] → (Flow 4.2)
  └─ Scroll and explore → {Track engagement}
  ↓
END
```

---

### Flow 3.3: Playback Controls & Features

```
[Story Player Screen - During Playback]
  ↓
<User interactions?>
  ├─ Tap pause → {Pause playback} → {Save position}
  ├─ Tap play → {Resume from saved position}
  ├─ Drag progress bar → {Seek to position} → {Resume playback}
  ├─ Tap skip back 15s → {Rewind 15 seconds}
  ├─ Tap skip forward 30s → {Skip ahead 30 seconds}
  ├─ Tap speed control → {Show options: 0.5x to 2.0x} → (Select) → {Update playback speed}
  ├─ Tap volume slider → {Adjust volume}
  ├─ Tap AirPlay/Bluetooth → {Show device picker} → (Select device) → {Route audio}
  ├─ Tap download → {Download for offline} → {Show progress} → {Success notification}
  ├─ Tap favorite → {Toggle favorite status} → {Animate}
  ├─ Tap share → [Share sheet] → (Options below)
  └─ Swipe down / tap back → {Minimize to mini-player} → [Return to feed]
  ↓
```

**Share Options:**
```
[Share Sheet]
  ├─ Share within family → {Show family member list} → (Select) → {Send in-app notification}
  ├─ Copy link → {Generate shareable link (private)} → {Copy to clipboard}
  └─ Download audio → {Export MP3} → {Save to files}
```

---

## 4. Story Creation & Threading Flows

### Flow 4.1: Record Original Story (User-Initiated)

```
[Home Screen]
  ↓
<User entry point?>
  ├─ Tap floating Record button (bottom) → [Recording Screen]
  ├─ Tap "Record" tab (bottom nav) → [Recording Screen]
  └─ Tap "Record a Story" CTA (empty state) → [Recording Screen]
  ↓
[Recording Screen]
{Request mic permission (if first time)}
  ↓
<Permission granted?>
  ├─ NO → {Show explanation} → {Link to settings} → END (user must grant in settings)
  └─ YES ↓
[Ready to Record State]
{Show: Large record button, optional prompt if available}
  ↓
(User taps record button)
  ↓
{Start recording}
{Show: Timer, waveform animation, pause button}
  ↓
[Recording in Progress]
  ↓
<User actions during recording?>
  ├─ Tap pause → {Pause recording} → {Timer stops} → <Resume?> → {Continue}
  ├─ Tap cancel → {Show confirmation: "Discard recording?"} → <Confirm?> → {Delete} → [Return to home]
  ├─ 15 min reached → {Show warning: "Max time reached"} → {Stop recording} → Jump to review
  └─ Tap done → {Stop recording} → Continue below
  ↓
{Save recording}
{Calculate duration}
  ↓
[Review Screen]
{Show: Play back button, duration, re-record option}
  ↓
(User taps play to review)
  ↓
{Play recording}
  ↓
<User satisfied?>
  ├─ NO → (Tap "Re-record") → {Discard} → [Return to recording screen]
  └─ YES ↓
(Tap "Continue")
  ↓
[Publish Options Screen]
{AI generates suggested title}
{Show: Title input, tag people, add photo, privacy}
  ↓
(User reviews AI title)
  ↓
<Edit title?>
  ├─ YES → (Tap edit) → {Open keyboard} → (Type new title) → {Update}
  └─ NO → Keep AI title
  ↓
<Tag people?>
  ├─ YES → (Tap "+") → {Show family member list} → (Select people) → {Add tags}
  └─ NO → Skip
  ↓
<Add photo?>
  ├─ YES → (Tap "Add Photo") → {Open camera/library} → (Select/take photo) → {Upload}
  └─ NO → Skip (will use default)
  ↓
(Select privacy option)
  ├─ "Share with all family" (default)
  ├─ "Share with specific people" → {Show picker} → (Select)
  └─ "Keep private for now"
  ↓
(Tap "Publish Story")
  ↓
{Upload audio to server}
{Process transcription}
{Create story entry in database}
{Set status based on privacy setting}
  ↓
<Requires admin approval?>
  ├─ YES → {Set status: Pending} → {Notify admin} → [Success screen: "Pending approval"]
  └─ NO → {Set status: Published} → {Notify family} → [Success screen: "Published!"]
  ↓
[Publishing Success Screen]
"Story Published! Your family will be notified."
[Button: Back to Stories] [Button: Record Another]
  ↓
<User action?>
  ├─ Tap "Back to Stories" → [Home Feed] → {Show new story at top}
  └─ Tap "Record Another" → [Recording Screen]
  ↓
END
```

**Technical Notes:**
- Auto-save draft every 30 seconds during recording
- If app crashes, recovery prompt on restart
- Max file size: 100MB (approx 15 min at high quality)

---

### Flow 4.2: Record Response to Story (Threading)

```
[Story Player Screen]
{User just finished listening to Grandpa's car story}
  ↓
[End-of-story prompt]
"What's your memory of this car?"
[Button: 🎤 Add Your Response]
  ↓
(User taps "Add Your Response")
  ↓
{Set context: Responding to Story ID #123}
  ↓
[Recording Screen - With Context]
{Show at top: "Responding to: 'My First Car' by Grandpa Joe"}
{Show prompt: "What's your memory of this car?"}
  ↓
(Same recording flow as 4.1)
  ↓
[Recording complete]
  ↓
[Review Screen]
{AI suggests title based on content + context}
Example: "Dad's Memory of the Mustang"
  ↓
(Review and edit as needed)
  ↓
(Tap "Publish Response")
  ↓
{Upload}
{Link to parent story (Story #123)}
{Create thread entry}
{Notify:
  - Original storyteller (Grandpa)
  - Others who responded
  - All family (if enabled)
}
  ↓
[Success Screen]
"Response added to thread!"
{Show: "Grandpa will be notified"}
  ↓
<Show prompt: "Who should respond next?">
[Suggested: Sister, Mom, Aunt]
[Button: Invite Sister]
  ↓
<User invites next person?>
  ├─ YES → {Send targeted notification to Sister:
             "Dad just shared his memory of Grandpa's car. What's yours?"}
         → [Chain started]
  └─ NO → Skip
  ↓
[Return to Thread View]
{Show updated thread with new response}
  ↓
END
```

**Threading Chain Logic:**
```
Original Story (Grandpa)
  └─ Response 1 (Dad) ← User just added this
      ↓
      {System: Identify next person in chain}
      {Logic:
        - Who's mentioned in original story?
        - Who hasn't responded yet?
        - Who's most likely to have perspective?
      }
      ↓
      {Send targeted prompt to Sister}
      "Dad just responded to Grandpa's car story.
       You grew up with that car too - what do you remember?"
      [Button: Add Your Memory]
      ↓
      <Sister responds?>
      ├─ YES → {Add Response 2}
      │        {Prompt next person: Aunt}
      │        {Chain continues...}
      └─ NO (after 48 hours) → {Send reminder}
                             → {Prompt alternate person}
```

**Key Mechanism:**
- **No one wants to break the chain** = social pressure
- Each response triggers notification to next logical person
- Visual indicator in thread: "Waiting for Sister's response"

---

### Flow 4.3: React to Story (Low-Effort Engagement)

```
[Story Player Screen - End of Playback]
  ↓
[Quick Reaction Prompt]
"What did you think?"
[❤️ Love it] [😂 Funny] [🤔 Interesting] [😢 Touching]
  ↓
(User taps reaction)
  ↓
{Record reaction in database}
{Show confirmation animation}
{Increment reaction count on story}
{Notify storyteller: "Dad loved your story 'My First Car'"}
  ↓
<Show follow-up prompt?>
"Want to share more?"
[Button: 🎤 Add Response] [Button: 💬 Leave Comment]
  ↓
<User action?>
  ├─ Tap Add Response → (Flow 4.2 - Full recording)
  ├─ Tap Leave Comment → {Open text input} → (Type brief comment) → {Post} → {Notify}
  └─ Dismiss → END
```

**Reaction Triggers:**
- Story creator gets notification
- Reactions visible to all family
- Most-reacted stories highlighted in feed

---

## 5. Engagement & Prompt Flows

### Flow 5.1: Daily Prompt Notification

```
{System: Daily prompt time (e.g., 9:00 AM)}
  ↓
{Select prompt based on:
  - Unanswered questions
  - Recent stories that need responses
  - Family drama/debate topics
  - AI-generated from recent activity
}
  ↓
{Send push notification}
"💭 Today's prompt: Did Grandpa really leave Dad at the bus station?"
  ↓
[User's phone]
  ↓
<User action?>
  ├─ Dismiss → {Mark as seen} → {Try again tomorrow} → END
  └─ Tap notification ↓
{Open app}
{Navigate to Prompt Center}
  ↓
[Prompt Center - Featured Prompt]
{Show prompt card}
{Show existing responses (if any)}
"💭 Did Grandpa really leave Dad at the bus station?"
  ├─ 👴 Grandpa says: YES (4 min, 3 responses)
  └─ 👨 Dad says: "It wasn't that simple..." (2 min)
  ↓
[Button: 🎤 Share Your Version]
  ↓
<User action?>
  ├─ Tap "Share Your Version" → [Recording Screen] → (Flow 4.1)
  ├─ Tap existing response → [Player] → {Listen} → <Then respond?>
  └─ Scroll to see other prompts
  ↓
END
```

**Prompt Selection Algorithm:**
```
Priority 1: Active threads with pending responses
  "Dad hasn't responded to Mom's story yet"
  
Priority 2: Controversial/debate topics
  "Who was the favorite child?" (encourage disagreement)
  
Priority 3: Unanswered questions to elders
  "Ask Grandma about her wedding"
  
Priority 4: AI-generated based on recent stories
  "Grandpa mentioned Uncle Bob - who has stories about him?"
  
Priority 5: Seasonal/timely
  "Tell me about your favorite holiday tradition"
```

---

### Flow 5.2: Thread Nudge (Social Pressure)

```
{Story Thread: "My First Car"}
  ├─ Grandpa (original)
  ├─ Dad (responded 2 days ago)
  └─ [Waiting for Sister]
  ↓
{System: 48 hours passed since Dad's response}
{Sister hasn't responded}
  ↓
{Send targeted notification to Sister}
"💬 Dad and Grandpa shared memories of the Mustang.
   You're the only one who hasn't shared yet!"
[Button: Add Your Memory]
  ↓
[Sister's phone]
  ↓
<Sister's action?>
  ├─ Tap notification → [Prompt Center] → {Show thread} → [Record button]
  └─ Dismiss → {Escalate pressure}
  ↓
{Wait another 24 hours}
  ↓
{Send stronger nudge}
"🔥 The family's waiting on you!
   Everyone's shared their memory of Grandpa's car except you."
{Show in app: "3/4 family members responded"}
  ↓
<Sister still doesn't respond?>
  ↓
{After 7 days: Switch to alternate prompt}
"We get it, you're busy! How about this easier one:
 Did you love or hate that car? (Just 30 seconds!)"
  ↓
END
```

**Nudge Escalation:**
1. Day 2: Gentle ("Don't forget!")
2. Day 4: Social pressure ("Everyone's waiting")
3. Day 7: Easier ask ("Just 30 seconds")
4. Day 14: Give up (don't be annoying)

---

### Flow 5.3: Inactivity Re-engagement

```
{User hasn't opened app in 7 days}
  ↓
{Send re-engagement notification}
"🎤 You have 3 unheard stories from your family"
  ↓
<User taps?>
  ├─ YES → [Open app] → [Home feed] → {Highlight unheard stories}
  └─ NO → {Wait 7 more days}
  ↓
{Day 14: No activity}
  ↓
{Send emotional appeal}
"Grandpa shared a story about you.
 He'd love to know you heard it. ❤️"
  ↓
<User taps?>
  ├─ YES → [Success! Re-engaged]
  └─ NO → {Wait 7 more days}
  ↓
{Day 21: Still no activity}
  ↓
{Send urgency trigger}
"⏰ Don't let family memories fade.
   Your family misses you in the conversation."
  ↓
<User taps?>
  ├─ YES → [Re-engaged]
  └─ NO → {Flag for admin} → {Suggest personal outreach}
  ↓
END
```

**Re-engagement Strategies:**
1. **Value reminder:** "3 unheard stories"
2. **Personal connection:** "Story about YOU"
3. **Emotional appeal:** "Grandpa would love..."
4. **Urgency:** "Don't let memories fade"
5. **FOMO:** "Family misses you"

---

### Flow 5.4: Prompt Suggestion to Elder

```
[User in Prompt Center]
  ↓
{Sees AI-generated prompt}
"💡 Ask Grandpa: What was your favorite childhood memory?"
  ↓
(User taps "Schedule for Next Call")
  ↓
{Add prompt to Grandpa's call queue}
{Show confirmation}
"Added to Grandpa's next call (Wednesday 10 AM)"
  ↓
{Wednesday morning: Call time}
  ↓
{Automated call to Grandpa}
  ↓
{In call: Play prompt}
"Your grandson suggested I ask you:
 What was your favorite childhood memory?"
  ↓
{Record Grandpa's response}
  ↓
{After call: Process and publish}
{Notify user who suggested prompt}
"🎤 Grandpa answered your question!
   'My Favorite Childhood Memory' is ready to listen."
  ↓
<User listens?>
  ↓
{Show acknowledgment}
"Thanks for asking great questions!
 Suggest another prompt?"
  ↓
END
```

**Prompt Queue Management:**
- Multiple family members can suggest prompts
- Elder gets 1-2 prompts per call (not overwhelming)
- Rotate between family-suggested and AI-generated
- Most-requested prompts prioritized

---

## 6. Family Tree Flows

### Flow 6.1: Explore Family Tree

```
[Home Screen]
  ↓
(Tap "Tree" tab in bottom navigation)
  ↓
[Family Tree Visualization]
{Render family tree graph}
{Load story counts for each person}
{Color-code by activity level}
  ↓
<User interaction?>
  ├─ Pinch to zoom → {Zoom in/out}
  ├─ Drag → {Pan around tree}
  ├─ Tap person node → (Flow 6.2)
  └─ Tap "+" button → (Flow 6.3 - Add family member)
  ↓
```

---

### Flow 6.2: View Person Details

```
[Family Tree]
  ↓
(User taps on "Grandpa Joe" node)
  ↓
[Person Detail Screen]
{Load profile}
{Load all stories by this person}
{Load all stories mentioning this person}
  ↓
{Display:
  - Profile photo
  - Name, relationship
  - Stats (story count, last active)
  - Next call time (if elder)
  - List of their stories
  - List of stories about them
}
  ↓
<User action?>
  ├─ Tap a story → [Story Player] → (Flow 3.2)
  ├─ Tap "See All Stories" → [Filtered feed: Grandpa's stories only]
  ├─ Tap "Send Him a Prompt" → [Prompt Composer] → (Flow below)
  └─ Tap "Edit" (if admin) → [Edit Profile] → (Admin flow)
  ↓
```

**Send Prompt Flow:**
```
(User taps "Send Him a Prompt")
  ↓
[Prompt Composer]
{Show: Text input field}
"What question should we ask Grandpa Joe?"
  ↓
(User types question: "Tell me about your time in the Navy")
  ↓
(Tap "Send")
  ↓
{Add to Grandpa's call queue}
{Show confirmation}
"Great question! We'll ask Grandpa on his next call (Wed 10 AM)."
  ↓
{Optional: "Want to be notified when he answers?"} → (Toggle ON/OFF)
  ↓
END
```

---

### Flow 6.3: Add Family Member (Admin)

```
[Family Tree]
  ↓
(Admin taps "+" button)
  ↓
[Add Family Member Screen]
{Show: Name, relationship, photo, contact}
  ↓
(Admin fills form)
  ├─ Name: "Uncle Bob"
  ├─ Relationship: "Uncle" (dropdown)
  ├─ Photo: (optional)
  ├─ Email/Phone: uncle.bob@email.com
  └─ Link to: "Mom" (who is his sibling)
  ↓
(Tap "Add & Invite")
  ↓
{Create profile}
{Send invitation email/SMS}
{Update family tree structure}
  ↓
[Confirmation]
"Uncle Bob has been invited!"
{Show: Pending status on tree}
  ↓
<Uncle Bob accepts invite?>
  ├─ YES → {Complete signup} → {Activate profile} → {Notify family} → {Tree updates}
  └─ NO (after 7 days) → {Send reminder} → {Show "Resend Invite" option to admin}
  ↓
END
```

---

### Flow 6.4: Family Stats & Gamification

```
[Family Tree Screen]
  ↓
(User taps "Stats" button)
  ↓
[Family Progress Dashboard]
{Display:
  - Total stories: 52
  - Active members: 8/10
  - This month: 12 stories
  - Most active: Grandpa Joe (24 stories)
  - Participation chart (bar graph)
  - Active threads
  - Milestones
}
  ↓
{Highlight gaps}
"⚪ 2 members haven't shared yet: Cousin Jake, Aunt Linda"
  ↓
[Button: Encourage Them]
  ↓
<User taps "Encourage Them"?>
  ↓
{Send targeted notifications}
"Hey Jake! Your family's building an amazing archive.
 Want to add your voice? 🎤"
  ↓
{Show social pressure}
"Everyone's contributing except you and Aunt Linda!"
  ↓
END
```

**Gamification Elements:**
- **Milestones:** 50, 100, 250, 500, 1000 stories
- **Streaks:** "7 days in a row with new stories"
- **Achievements:** "3 generations active", "Everyone participated this month"
- **Leaderboards:** (Subtle - don't make it competitive, collaborative)

---

## 7. Admin & Management Flows

### Flow 7.1: Review Pending Story (Admin)

```
{New story recorded and processed}
{Status: Pending Review}
  ↓
{Send notification to admin}
"🎤 New story from Dad needs review"
  ↓
[Admin's phone]
  ↓
<Admin taps notification?>
  ↓
[Admin Dashboard - Web or App]
{Navigate to "Pending Review" section}
  ↓
[Story Card: "Dad's Response: Car Story"]
{Show:
  - Title, duration
  - Storyteller
  - Timestamp
  - Play button
  - Actions: Approve, Edit, Reject
}
  ↓
(Admin taps "Play")
  ↓
{Play audio}
[Admin listens to story]
  ↓
<Admin decision?>
  ├─ Approve ↓
  │   (Tap "✓ Approve")
  │   {Set status: Published}
  │   {Send notifications to family}
  │   {Update feed}
  │   {Notify storyteller: "Your story is now live!"}
  │   END
  │
  ├─ Edit ↓
  │   (Tap "Edit")
  │   [Edit Screen]
  │   {Show: Title, description, tags, privacy}
  │   (Admin makes changes)
  │   (Tap "Save & Approve")
  │   {Update metadata}
  │   {Set status: Published}
  │   {Notify family}
  │   END
  │
  └─ Reject ↓
      (Tap "✕ Reject")
      [Rejection Dialog]
      "Why are you rejecting this story?"
      [ ] Inappropriate content
      [ ] Poor audio quality
      [ ] Accidental recording
      [ ] Other: [text input]
      (Select reason)
      (Tap "Confirm Rejection")
      {Set status: Rejected}
      {Notify storyteller with reason}
      {Option to re-record}
      END
```

**Auto-Approve Option:**
```
[Admin Settings]
  ├─ Auto-approve stories from: [Select members]
  ├─ Auto-approve all stories: [Toggle]
  └─ Always review stories with flagged content: [Toggle]
```

---

### Flow 7.2: Manage Elder Call Schedule (Admin)

```
[Admin Dashboard]
  ↓
(Navigate to "Elder Call Schedule")
  ↓
[Call Schedule Screen]
{List all elders with their schedules}
  ├─ Grandpa Joe: Wednesdays at 10:00 AM EST
  └─ Grandma Mary: Fridays at 2:00 PM EST
  ↓
(Admin taps "Edit Schedule" for Grandpa Joe)
  ↓
[Edit Schedule Modal]
{Show:
  - Current: Wednesdays at 10:00 AM EST
  - Day picker
  - Time picker
  - Timezone selector
  - Frequency: Weekly (default) / Bi-weekly / Monthly
}
  ↓
(Admin makes changes)
  ├─ Change day: Wednesday → Thursday
  ├─ Change time: 10:00 AM → 11:00 AM
  └─ Keep timezone: EST
  ↓
(Tap "Save Changes")
  ↓
{Update call queue}
{Cancel next scheduled call}
{Schedule new call with updated time}
{Notify Grandpa Joe via SMS}
  "Hi Grandpa Joe! Your weekly story call has been moved to
   Thursdays at 11:00 AM. See you then!"
  ↓
[Confirmation]
"Schedule updated! Next call: Thursday, Dec 28 at 11:00 AM"
  ↓
END
```

---

### Flow 7.3: Handle Missed Call (Admin Notification)

```
{Scheduled call to Grandpa Joe}
{Call time: Wednesday 10:00 AM}
  ↓
{System initiates call}
  ↓
<Grandpa answers?>
  ├─ YES → (Normal call flow - 2.1)
  └─ NO → After 3 rings, no answer ↓
{Mark call as: Missed}
{Cancel call}
  ↓
{Auto-retry logic}
{Schedule retry: +24 hours (Thursday 10:00 AM)}
  ↓
{Notify admin}
"📞 Missed call: Grandpa Joe didn't answer.
   We'll try again tomorrow at 10 AM.
   Want to call him yourself?"
[Button: I'll Call Him] [Button: Reschedule] [Button: Skip This Week]
  ↓
<Admin action?>
  ├─ "I'll Call Him" → {Show phone number} → (Admin manually reaches out) → END
  │
  ├─ "Reschedule" → [Time Picker] → (Select new time) → {Update schedule} → END
  │
  └─ "Skip This Week" → {Cancel retry} → {Next call: Next Wednesday} → END
  ↓
{Retry next day (Thursday 10:00 AM)}
  ↓
<Grandpa answers?>
  ├─ YES → {Success! Proceed with call}
  └─ NO → {Mark: 2nd missed call} → {Notify admin with urgency}
  ↓
END
```

**Escalation After Multiple Missed Calls:**
- 2 missed: "Might want to check on Grandpa Joe"
- 3 missed: "❗Important: Grandpa Joe hasn't answered 3 calls"

---

### Flow 7.4: Manage Subscription (Admin)

```
[Admin Dashboard]
  ↓
(Navigate to "Subscription")
  ↓
[Subscription Screen]
{Display:
  - Current plan: Medium Family ($34.99/mo)
  - Members: 10/10 limit
  - Elders: 2/2 limit
  - Next billing: Jan 20, 2026
  - Payment method: Visa •••• 1234
}
  ↓
<Admin action?>
  ├─ "Upgrade Plan" → (Flow below)
  ├─ "Update Payment" → {Stripe modal} → (Update card) → {Save}
  ├─ "View Billing History" → [List of invoices] → (Download)
  └─ "Cancel Subscription" → (Flow below)
  ↓
```

**Upgrade Flow:**
```
(Admin taps "Upgrade Plan")
  ↓
[Plan Selection]
{Highlight current plan}
{Show reason to upgrade}
"You have 10 members (at limit). Upgrade to add more family!"
  ↓
Plans:
  ├─ Small (1-5 members) - $19.99/mo [Too small]
  ├─ Medium (6-10 members) - $34.99/mo [CURRENT]
  ├─ Large (11-20 members) - $49.99/mo [Recommended]
  └─ Extended (21+ members) - $79.99/mo
  ↓
(Admin selects "Large")
  ↓
{Calculate prorated amount}
"Upgrade to Large for $15 more/month
 (prorated: $12.50 today, $49.99 starting Feb 1)"
  ↓
(Tap "Upgrade")
  ↓
{Charge prorated amount}
{Update subscription}
{Update limits}
  ↓
[Confirmation]
"Upgraded to Large Family Plan!
 You can now add up to 20 members and 3 elders."
  ↓
END
```

**Cancel Flow:**
```
(Admin taps "Cancel Subscription")
  ↓
[Cancellation Warning]
"⚠️ Are you sure?
 
 If you cancel:
 ❌ No more scheduled calls to elders
 ❌ No new stories can be recorded
 ✅ Existing stories remain accessible (read-only)
 
 Want to preserve your stories forever?
 [Consider Legacy Archive - $499 one-time]"
  ↓
<Admin choice?>
  ├─ "Keep Subscription" → [Return to dashboard]
  │
  ├─ "Buy Legacy Archive" → {Stripe checkout} → {Purchase $499} → {Grant lifetime access}
  │                       → {Cancel subscription}
  │                       → [Confirmation: "Your stories are safe forever"]
  │
  └─ "Cancel Anyway" ↓
      [Final Confirmation]
      "Last chance! Are you absolutely sure?"
      [Button: No, Keep My Subscription] [Button: Yes, Cancel]
      ↓
      (Tap "Yes, Cancel")
      ↓
      {Set cancellation date: End of current period}
      {Send email confirmation}
      {Notify all family members}
      ↓
      [Cancellation Confirmed]
      "Your subscription will end on Jan 20, 2026.
       Until then, everything works normally.
       Want to reconsider? You can reactivate anytime."
      ↓
      END
```

---

## 8. Edge Cases & Error Flows

### Flow 8.1: Poor Audio Quality

```
{User records story}
{Upload to server}
  ↓
{AI transcription process}
  ↓
<Transcription confidence score?>
  ├─ High (>90%) → {Process normally}
  │
  ├─ Medium (70-90%) → {Flag for admin review}
  │                  → {Show warning: "Audio quality is OK but not great"}
  │                  → {Option to re-record}
  │
  └─ Low (<70%) → {Auto-reject}
                 → {Notify user}
                 ↓
[Error Screen]
"😕 We couldn't understand your recording.
 
 This might be because:
 • Background noise was too loud
 • Microphone was too far away
 • Connection was unstable
 
 Would you like to try again?"
[Button: Re-record] [Button: Save Draft & Try Later]
  ↓
<User choice?>
  ├─ Re-record → {Return to recording screen} → {Try again}
  └─ Save Draft → {Save locally} → {Retry later with better conditions}
  ↓
END
```

---

### Flow 8.2: Elder Call Technical Issues

```
{Automated call initiated}
  ↓
<Call connection status?>
  ├─ Busy signal → {Wait 5 min} → {Retry} → <Success?> → {Continue} or {Mark missed}
  │
  ├─ No answer → {Retry in 24 hours} → (Flow 7.3)
  │
  ├─ Voicemail → {Detect voicemail greeting}
                → {Don't leave message}
                → {Hang up}
                → {Mark as: Went to voicemail}
                → {Retry in 24 hours}
                → {Notify admin}
  │
  └─ Elder answers but confused → {AI detection: Confusion signals}
                                → {Simplify prompts}
                                → {Offer to call back}
                                ↓
      "I'm sorry, Grandpa Joe. Would you like me to call back later?"
      <Elder says yes?>
      ├─ YES → {Ask when} → {Reschedule}
      └─ NO → {Continue with simpler prompts}
  ↓
END
```

**Technical Error Handling:**
- Network issues during call: Auto-reconnect, save partial recording
- Server down during upload: Queue locally, retry when back online
- Transcription service unavailable: Queue, process when available

---

### Flow 8.3: Inappropriate Content Flagged

```
{Story uploaded and transcribed}
  ↓
{AI content moderation scan}
  ↓
<Flags detected?>
  ├─ Profanity → {Flag: Low severity} → {Allow but notify admin}
  ├─ Personal info (SSN, credit card) → {Flag: Medium} → {Block, notify admin urgently}
  └─ Hate speech, violence → {Flag: High} → {Auto-block} → {Notify admin immediately}
  ↓
{For medium/high flags:}
  ↓
{Set status: Blocked}
{Do NOT publish}
{Notify admin}
  ↓
[Admin Dashboard Alert]
"⚠️ Story blocked due to: Sensitive personal information detected
 
 Story: 'My Bank Account' by Grandpa Joe
 Detected: Possible social security number
 
 Action needed:
 [Review & Edit] [Approve Anyway] [Delete]"
  ↓
<Admin reviews?>
  ↓
(Admin plays audio, reviews transcript)
  ↓
<Admin decision?>
  ├─ False positive → (Approve) → {Publish}
  ├─ Edit needed → (Edit) → {Remove sensitive info} → {Publish}
  └─ Actually inappropriate → (Delete) → {Notify storyteller} → {Explain policy}
  ↓
END
```

---

### Flow 8.4: Family Member Conflict

```
{Story published: "The Truth About Uncle Bob" by Aunt Sarah}
  ↓
{Uncle Bob listens and is upset}
  ↓
(Uncle Bob taps ⋮ menu on story)
  ↓
[More Menu]
  ├─ Favorite
  ├─ Download
  ├─ Share
  └─ ⚠️ Report
  ↓
(Taps "Report")
  ↓
[Report Dialog]
"Why are you reporting this story?"
  [ ] Inaccurate / Not true
  [ ] Hurtful or offensive
  [ ] Private information shared without consent
  [ ] Other
  ↓
(Selects "Inaccurate / Not true")
  ↓
(Optional text: "This didn't happen the way she described")
  ↓
(Tap "Submit Report")
  ↓
{Create report ticket}
{Notify admin}
{Flag story (not hidden, just flagged)}
  ↓
[Admin Dashboard]
"🚩 Story reported by Uncle Bob
 Story: 'The Truth About Uncle Bob' by Aunt Sarah
 Reason: Inaccurate
 Comment: 'This didn't happen the way she described'
 
 Actions:
 [Contact Uncle Bob] [Contact Aunt Sarah] [Hide Story] [Add Disclaimer] [Do Nothing]"
  ↓
<Admin decision?>
  ├─ Contact both parties → {Mediate} → <Resolution?>
  ├─ Hide story → {Remove from feed} → {Notify Aunt Sarah}
  ├─ Add disclaimer → {Append note: "Uncle Bob disputes this version"}
  └─ Do nothing → {Family drama is part of life} → {Let them work it out}
  ↓
END
```

**Conflict Resolution Best Practices:**
- Encourage both parties to record THEIR version
- Frame as "multiple perspectives" not "one truth"
- Use threading to show different viewpoints
- Reminder: Private family space, keep it respectful

---

### Flow 8.5: Account Recovery (Forgot Password)

```
[Login Screen]
  ↓
(Tap "Forgot Password?")
  ↓
[Password Reset Screen]
"Enter your email address"
[Input: Email]
  ↓
(Enter email: user@email.com)
(Tap "Send Reset Link")
  ↓
{Look up user by email}
  ↓
<User exists?>
  ├─ NO → {Still send generic confirmation (security best practice)}
  │       "If that email is in our system, you'll receive a reset link."
  │       END
  └─ YES ↓
{Generate reset token (expires in 1 hour)}
{Send email with reset link}
  ↓
[Confirmation Screen]
"Check your email!
 We sent a password reset link to user@email.com.
 
 Didn't receive it?
 [Resend Link] [Try Different Email]"
  ↓
{User checks email}
  ↓
[Email: Password Reset]
"Click here to reset your password: [LINK]
 This link expires in 1 hour."
  ↓
(User clicks link)
  ↓
{Open app or web}
{Validate token}
  ↓
<Token valid?>
  ├─ NO (expired or invalid) → [Error: "Link expired. Request a new one."]
  └─ YES ↓
[Reset Password Screen]
"Create a new password"
[Input: New Password]
[Input: Confirm Password]
  ↓
{Validate password strength}
  ↓
<Passwords match and strong?>
  ├─ NO → {Show errors} → (Fix) → Loop back
  └─ YES ↓
(Tap "Reset Password")
  ↓
{Hash and save new password}
{Invalidate reset token}
{Log out all other sessions}
  ↓
[Success Screen]
"Password reset successfully!
 You can now log in with your new password."
[Button: Log In]
  ↓
(Tap Log In)
  ↓
[Login Screen]
{Pre-fill email}
  ↓
(Enter new password)
(Tap Log In)
  ↓
{Authenticate}
  ↓
[Home Screen]
  ↓
END
```

---

### Flow 8.6: Data Export (User Requests All Data)

```
[Settings] → [Privacy & Data]
  ↓
(Tap "Download My Data")
  ↓
[Data Export Screen]
"Request a copy of all your family's stories
 and data. This may take a few hours.
 
 What's included:
 ✓ All audio files
 ✓ Transcripts
 ✓ Photos and attachments
 ✓ Family tree structure
 ✓ Metadata (dates, tags, etc.)
 
 Format: ZIP file with organized folders
 Delivery: Email link when ready"
  ↓
(Tap "Request Export")
  ↓
{Create export job}
{Queue for background processing}
  ↓
[Confirmation]
"Export requested! We'll email you when it's ready.
 (Usually within 2-4 hours)"
  ↓
{Background process:}
{Gather all family data}
{Compile audio files}
{Export transcripts as text files}
{Create family tree JSON}
{Generate ZIP file}
{Upload to secure temporary storage}
{Generate download link (expires in 7 days)}
  ↓
{Send email notification}
  ↓
[Email: "Your data export is ready"]
"Your family data export is ready to download.
 
 [Download Now] (expires in 7 days)
 
 File size: 1.2 GB"
  ↓
(User clicks Download)
  ↓
{Download ZIP file}
  ↓
END
```

**Data Export Structure:**
```
johnson_family_export_20251220.zip
  ├─ audio/
  │   ├─ grandpa_joe_my_first_car_20251220.mp3
  │   ├─ dad_response_car_20251221.mp3
  │   └─ ...
  ├─ transcripts/
  │   ├─ grandpa_joe_my_first_car_20251220.txt
  │   └─ ...
  ├─ photos/
  │   ├─ profile_grandpa_joe.jpg
  │   └─ ...
  ├─ family_tree.json
  ├─ story_metadata.csv
  └─ README.txt
```

---

## Summary: Critical User Journeys

### Top 5 Most Important Flows (Priority Order):

1. **Flow 2.1: Scheduled Automated Call (Elder)**
   - This is THE core value prop
   - Must be seamless and delightful
   - Every step must feel natural

2. **Flow 4.2: Record Response (Threading)**
   - The killer feature that drives retention
   - Social pressure mechanism
   - Creates ongoing engagement

3. **Flow 3.1: Listen to New Story (Push Notification)**
   - Primary consumption behavior
   - Must be frictionless
   - Hooks user into emotional experience

4. **Flow 1.1: Complete Onboarding**
   - First impression
   - Get to value quickly
   - Sets up entire system (elder + family)

5. **Flow 5.2: Thread Nudge (Social Pressure)**
   - Retention driver
   - Participation pressure
   - "Don't break the chain" mechanic

---

## Metrics to Track Per Flow

| Flow | Success Metric | Target |
|------|----------------|--------|
| Onboarding (1.1) | % who complete setup | >80% |
| Elder Call (2.1) | Call completion rate | >85% |
| Story Listen (3.1) | Listen-through rate | >70% |
| Record Response (4.2) | Response rate per story | >40% |
| Thread Nudge (5.2) | Nudge response rate | >30% |
| Daily Prompt (5.1) | Prompt response rate | >25% |
| Re-engagement (5.3) | Reactivation rate | >15% |

---

**End of User Flows Document**

*These flows should be validated through user testing and iterated based on real behavior.*
