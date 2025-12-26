# Product Requirements Document (PRD)
# Family Memory App: Legacy-as-a-Service

**Document Version:** 1.0  
**Last Updated:** December 20, 2025  
**Status:** Draft  

---

## Executive Summary

### Product Vision
A voice-first family memory platform that automatically captures elders' stories, transforms them into private family podcasts, and builds a living family legacy through multi-generational story threads and participation pressure.

### One-Liner
Automatic voice capture + private family podcast + interactive story threads = a living family legacy that grows through social pressure and emotional urgency.

### Key Differentiator
**This is not a scrapbook app.** This is Legacy-as-a-Service with real retention mechanics:
- Voice-first (no typing required for elders)
- Asynchronous, multi-generation collaboration
- Built-in social pressure through story threads
- Mortality + regret aversion trigger
- Private family networks, not public social

---

## Problem Statement

### The Core Problem
Family stories, wisdom, and history die silently when elders pass away.

### Why Current Solutions Fail
1. **Elders won't engage** with complex apps or typing-based interfaces
2. **Nostalgia apps lack:**
   - Habit loops
   - Ongoing engagement
   - Multi-user collaboration
   - Emotional urgency
3. **No participation mechanism** - passive archives don't create sustained engagement
4. **Individual-focused** - family legacy is inherently collaborative but current tools treat it as solo activity

### Impact of Problem
- Irreplaceable family history lost forever
- Generational wisdom never passed down
- Family connections weaken across generations
- Regret and guilt after elders pass ("I should have asked more questions")

---

## Target Users

### Primary Personas

#### 1. Elders / Grandparents (Content Creators)
**Characteristics:**
- Age: 65+
- Do not type or use complex apps
- Only comfortable with phone calls or simple voice recording
- Have decades of stories, wisdom, and family history
- Want to be heard and remembered

**Needs:**
- Zero-friction way to share stories
- No learning curve
- Feels natural (like a phone conversation)
- Validation that someone is listening

#### 2. Parents (Buyers & Managers)
**Characteristics:**
- Age: 35-55
- Have aging parents
- Financially stable (can pay subscription)
- Tech-comfortable
- Feel urgency about preserving parents' stories

**Needs:**
- Easy setup and management
- Handle consent, editing, family invites
- Control privacy and access
- Peace of mind that stories are being captured
- Assuage guilt about not spending enough time with parents

**Pain Points:**
- Don't have time to interview parents regularly
- Don't know what questions to ask
- Worry stories will be lost forever

#### 3. Children / Grandchildren (Consumers & Contributors)
**Characteristics:**
- Age: 5-35
- Consume content naturally
- Used to podcasts, TikTok, social media
- Curious about family history but won't seek it out proactively

**Needs:**
- Easy, entertaining format (audio)
- Low barrier to participation
- Social validation (others engaging too)
- Connection to family identity

---

## Solution Overview

### Core Solution Architecture

```
Voice Capture → AI Processing → Private Podcast Feed → Story Threads → Family Tree
```

### The 5-Part System

#### 1. Automated Voice Capture (Low Friction)
- **Scheduled voice calls** to elders (weekly/bi-weekly)
- **Smart prompts** that extract:
  - Life stories
  - Family history
  - Confessions, wisdom, drama
  - Career and relationships
- **Elder just answers the phone and talks**
- No app required for elders

#### 2. Private Family Podcast Feed
- Stories are automatically:
  - Transcribed
  - Cleaned and edited
  - Auto-titled (e.g., "The Day Grandpa Forgot Dad at the Bus Station")
  - Dropped into Spotify-like private feed
- **Push notifications:** "New story from Grandpa just dropped"
- **Playback features:** Speed control, bookmarks, favorites

#### 3. Story Threads (THE KILLER FEATURE)
**How it works:**
- Every story becomes a living thread
- One person records → App invites next person in family tree to add:
  - Their version
  - A reaction
  - A correction
  - Additional context

**Creates multi-POV chains:**
- Reddit-style threading
- Group chat dynamics
- Rashomon-style storytelling

**Psychological hook:**
⚠️ **No one wants to be the person who breaks the chain.**

**Examples:**
```
Grandpa's Story: "I was the favorite child"
  └─ Dad's Response: "That's not how I remember it..."
      └─ Aunt's Response: "You're both wrong, here's what really happened"
          └─ Cousin's Response: "Wait, I have photos that prove..."
```

#### 4. Daily/Weekly Prompts (Habit Engine)
**Smart prompts sent to family members:**
- "Did Grandpa really leave Dad at the bus station?"
- "Who was Grandpa's favorite child?"
- "What actually happened at Mom's wedding?"
- "Ask Grandma about her first job"

**Why it works:**
- No thinking required → just react
- Disagreement = engagement
- Family drama = retention
- Nostalgia + curiosity = opens app

#### 5. Visual Family Memory Tree
**Features:**
- Stories auto-tagged to:
  - Events (weddings, births, moves)
  - Life stages (childhood, career, retirement)
  - People (auto-linked to family members)
  - Themes (funny, dramatic, wisdom, historical)
- **Growth mechanics:**
  - Tree only grows when new members contribute
  - Visual gaps show missing stories
  - Branches blocked until someone else records

**Gamification (subtle):**
- "Your branch needs 3 more stories to unlock"
- "Mom hasn't shared her perspective yet"
- Visual completeness indicators

---

## Core Features (MVP)

### Must-Have Features (Phase 1)

#### For Elders
1. **Automated Voice Calls**
   - Scheduled calls at preset times
   - Smart IVR system with prompts
   - Natural conversation flow
   - Call recording and storage

2. **Simple Voice Recording**
   - One-button voice recording (if app used)
   - Phone call option (no app needed)
   - Automatic save and upload

#### For Parents (Admins)
3. **Family Setup & Management**
   - Create family account
   - Invite family members (with roles)
   - Set up elder call schedules
   - Manage privacy settings
   - Consent management

4. **Story Management**
   - Edit/trim recordings
   - Add titles and descriptions
   - Approve/publish stories
   - Delete if needed

5. **Notification Controls**
   - Set notification preferences per family member
   - Moderate content before release

#### For All Family Members
6. **Private Podcast Feed**
   - Chronological story feed
   - Play/pause/speed controls
   - Bookmarks and favorites
   - Download for offline

7. **Story Threads**
   - Listen to original story
   - Record response/reaction (voice)
   - See all responses in thread
   - Notifications when someone responds

8. **Smart Prompts**
   - Daily/weekly prompt notifications
   - "React to this story" prompts
   - "Ask [Elder] about..." prompts
   - Easy one-tap to record response

9. **Family Tree View**
   - Visual representation of family
   - Stories linked to people
   - Completion indicators
   - Timeline view

#### Platform Features
10. **AI Processing**
    - Speech-to-text transcription
    - Auto-titling of stories
    - Content moderation (optional)
    - Smart tagging (people, events, themes)

11. **Privacy & Security**
    - End-to-end encryption
    - Private family networks only
    - No public sharing (by default)
    - Granular access controls

12. **Subscription Management**
    - Family-wide subscription (not individual)
    - Payment by admin
    - Tiered by family size

---

## User Flows

### Flow 1: Initial Setup (Parent/Admin)
1. Sign up and create family account
2. Add family members (name, role, contact)
3. Set up elder profile and call schedule
4. Customize privacy settings
5. Invite family members via email/SMS
6. First automated call scheduled

### Flow 2: Elder Voice Capture (Automated Call)
1. Elder receives scheduled call
2. Greeting: "Hi Grandpa, this is your family memory keeper"
3. Prompt: "Tell me about your first job"
4. Elder speaks naturally (3-10 minutes)
5. System: "Thank you! Your family will love hearing this."
6. Call ends, recording auto-uploaded
7. AI processes: transcribe, title, tag

### Flow 3: Story Published → Thread Starts
1. Admin reviews story, approves
2. Story published to family podcast feed
3. **Push notification to all:** "New story from Grandpa: 'My First Car'"
4. Family members listen
5. **Thread prompt sent to Dad:** "Grandpa talked about his first car. Do you remember it differently?"
6. Dad records 2-minute response
7. **Thread prompt sent to Aunt:** "Dad responded to Grandpa's car story. Want to add your memory?"
8. Thread grows, family engagement increases

### Flow 4: Daily Prompt Engagement
1. Grandchild receives prompt: "Did Grandma really elope?"
2. Taps notification → sees prompt
3. Taps "Ask Grandma" → schedules question for next call
4. OR taps "I know this story" → records their version
5. Grandma gets question on next call
6. Story published → new thread starts

### Flow 5: Family Tree Exploration
1. Family member opens app
2. Views family tree visualization
3. Sees gaps: "Aunt Sarah hasn't shared stories yet"
4. Taps Grandpa's branch → sees all his stories
5. Filters by theme: "Funny stories"
6. Discovers new story, listens, reacts

---

## Technical Requirements (High-Level)

### Platform
- **Mobile:** iOS and Android native apps
- **Web:** Admin dashboard for parents
- **Voice:** Telephony integration (Twilio or similar)

### Key Technical Components
1. **Voice Infrastructure**
   - Automated call system (IVR)
   - Call recording and storage
   - Voice recording in-app
   - Audio streaming/playback

2. **AI/ML Pipeline**
   - Speech-to-text (Whisper, AssemblyAI, or similar)
   - Auto-titling (GPT-4 or similar)
   - Content tagging and categorization
   - Smart prompt generation

3. **Database & Storage**
   - Audio file storage (S3 or similar)
   - Metadata database (stories, users, relationships)
   - Transcripts and tags
   - Family tree structure

4. **Backend Services**
   - User authentication and authorization
   - Family management
   - Notification system (push, SMS, email)
   - Subscription/payment processing (Stripe)
   - API for mobile apps

5. **Security**
   - End-to-end encryption for audio
   - Role-based access control
   - GDPR/privacy compliance
   - Secure payment processing

### Performance Requirements
- Audio upload: < 30 seconds for 10-minute recording
- Transcription: Within 5 minutes of recording
- Push notifications: < 1 minute latency
- App load time: < 2 seconds

---

## Success Metrics

### North Star Metric
**Family Engagement Rate:** % of family members who contribute (record or react) at least once per week

### Key Metrics

#### Acquisition
- Families signed up per month
- Average family size
- Cost per acquisition (CPA)

#### Activation
- % of families who complete setup
- % of families with first elder call completed
- % of families with 3+ stories published
- Time to first story published

#### Engagement
- Stories recorded per family per month
- Thread responses per story (average)
- Daily/weekly active users (DAU/WAU)
- Prompt response rate
- Listen-through rate (% who finish stories)

#### Retention
- Monthly/annual subscription retention
- % of families still active after 3/6/12 months
- Elder call completion rate

#### Revenue
- MRR/ARR
- Average revenue per family
- Churn rate
- Lifetime value (LTV)

#### Quality
- Average story length
- Stories per elder per month
- Multi-generational participation (% families with 3+ generations active)

---

## Monetization Strategy

### Subscription Model
**Family-Based Subscription** (not individual)

#### Pricing Tiers (Based on Family Size)

**Tier 1: Small Family (1-5 members)**
- $19.99/month or $199/year
- 1 elder with scheduled calls
- Unlimited stories and storage
- All core features

**Tier 2: Medium Family (6-10 members)**
- $34.99/month or $349/year
- 2 elders with scheduled calls
- Unlimited stories and storage
- All core features
- Priority support

**Tier 3: Large Family (11-20 members)**
- $49.99/month or $499/year
- 3 elders with scheduled calls
- Unlimited stories and storage
- All core features
- Priority support
- Advanced editing tools

**Tier 4: Extended Family (21+ members)**
- $79.99/month or $799/year
- Up to 5 elders with scheduled calls
- Unlimited stories and storage
- All features
- White-glove support
- Professional editing service (optional add-on)

#### Add-Ons
- **Extra Elder Calls:** $10/month per additional elder
- **Professional Editing:** $50/month (human editor cleans up stories)
- **Printed Memory Books:** $99-299 (physical book generated from stories)
- **Legacy Archive:** $499 one-time (lifetime access guarantee, even if subscription ends)

### Why This Pricing Works
- **Parents pay, everyone benefits**
- **Kids inherit the archive forever** (with Legacy Archive purchase)
- **Family-wide value** justifies higher price point
- **Emotional purchase** (preserving legacy) = less price sensitivity
- **Subscription ensures ongoing capture**, not just one-time project

---

## Roadmap & Phases

### Phase 1: MVP (Months 1-3)
**Goal:** Validate core value proposition with 50 beta families

**Features:**
- Automated voice calls for elders
- Private family podcast feed
- Basic story threads (record response)
- Simple family management
- Mobile apps (iOS/Android)
- Basic prompts

**Success Criteria:**
- 50 beta families onboarded
- 80%+ elder call completion rate
- 3+ stories per family
- 50%+ thread response rate
- NPS > 50

### Phase 2: Engagement Loop (Months 4-6)
**Goal:** Prove retention mechanics work

**Features:**
- Smart prompts system (AI-generated)
- Family tree visualization
- Advanced threading (nested responses)
- Reaction types (agree, disagree, funny, etc.)
- Enhanced notification system
- In-app listening improvements

**Success Criteria:**
- 30%+ weekly active users
- 5+ stories per family per month
- 60%+ families still active at month 6
- Prompt response rate > 40%

### Phase 3: Growth & Polish (Months 7-12)
**Goal:** Scale to 1,000 families

**Features:**
- Referral program (invite extended family)
- Advanced AI features (topic detection, auto-highlights)
- Story discovery (search, filters, recommendations)
- Memory books (physical products)
- Web dashboard for admins
- Professional editing service

**Success Criteria:**
- 1,000 paying families
- $50k+ MRR
- < 5% monthly churn
- 70%+ families with 3+ generations active

### Phase 4: Platform Expansion (Year 2+)
**Potential features:**
- Video story capture
- Photo/document integration
- AI-generated family history summaries
- Inter-family sharing (opt-in, for genealogy)
- Legacy planning tools
- Integration with estate planning services

---

## Competitive Landscape

### Direct Competitors
- **StoryWorth:** Annual book of stories via email prompts (static, no threading)
- **Remento:** Voice-based memory capture (individual-focused, no family collaboration)
- **LifeTales:** Story recording app (elder must use app, no automation)

### Why We Win
| Feature | This App | StoryWorth | Remento | LifeTales |
|---------|----------|------------|---------|-----------|
| Voice-first for elders | ✅ Automated calls | ❌ Email-based | ⚠️ App required | ⚠️ App required |
| Multi-generational threads | ✅ Core feature | ❌ | ❌ | ❌ |
| Participation pressure | ✅ Social mechanics | ❌ | ❌ | ❌ |
| Ongoing engagement | ✅ Prompts + threads | ⚠️ Annual only | ⚠️ Low retention | ⚠️ Low retention |
| Private podcast feed | ✅ | ❌ | ⚠️ Basic | ❌ |
| Family collaboration | ✅ Built for it | ❌ Individual | ❌ Individual | ⚠️ Limited |

### Indirect Competitors
- Ancestry.com (genealogy, not stories)
- Family group chats (WhatsApp, etc.) - ephemeral, no structure
- Google Photos / Apple Photos - passive, no story capture

---

## Risks & Mitigations

### Risk 1: Elder Adoption (Call Completion)
**Risk:** Elders don't answer calls or find them annoying

**Mitigation:**
- Set up calls with elder's input (preferred time/day)
- Caller ID shows family name/photo
- Option for elder to initiate calls (call a number anytime)
- Gradual introduction (first call is short, introduces concept)
- Admin can adjust frequency

### Risk 2: Low Family Participation
**Risk:** Only 1-2 family members engage, others ignore

**Mitigation:**
- Strong onboarding that gets 5+ family members set up
- Prompts specifically target inactive members
- FOMO mechanics (show who's participated, who hasn't)
- Family competition (subtle gamification)
- Admin tools to encourage participation

### Risk 3: Privacy Concerns
**Risk:** Family members uncomfortable with recording/sharing

**Mitigation:**
- Explicit consent from all participants
- Granular privacy controls (who can see what)
- Option to keep stories private until approved
- Clear data policies (not sold, not public)
- Option to delete at any time

### Risk 4: Content Moderation
**Risk:** Inappropriate or hurtful content in stories/threads

**Mitigation:**
- Admin review before publishing (optional)
- Ability to delete/hide content
- Private family networks (not public)
- AI flagging of sensitive content
- Family guidelines/norms established during onboarding

### Risk 5: Churn After Elder Passes
**Risk:** Families cancel subscription after capturing elder's stories

**Mitigation:**
- Multi-generational value (capture parents too)
- Ongoing prompts keep engagement high
- New features (other elders, extended family)
- Legacy Archive (one-time purchase for lifetime access)
- Shift focus to family bonding, not just preservation

---

## Open Questions

### Product Questions
1. **Call Length:** What's optimal length for elder calls? 5 min? 10 min? 30 min?
2. **Prompt Frequency:** Daily prompts too much? Weekly better?
3. **Thread Depth:** Should threads be nested (Reddit-style) or flat (Facebook-style)?
4. **Content Review:** Should all content require admin approval, or auto-publish?
5. **Non-Voice Participation:** Should younger kids be able to draw/write responses instead of voice?

### Technical Questions
1. **Voice Quality:** What's minimum acceptable audio quality for transcription?
2. **Storage Costs:** How much audio storage per family per year?
3. **AI Accuracy:** What accuracy rate needed for auto-titling/tagging to be useful?
4. **Scalability:** Can automated call system handle 1,000+ concurrent calls?

### Business Questions
1. **Price Point:** Is $20-80/month too high? Too low?
2. **Free Trial:** Offer 30-day free trial? Or money-back guarantee?
3. **Target Market:** Start with US only, or international from day 1?
4. **Sales Channel:** B2C direct, or partner with senior living facilities?

---

## Appendix

### User Research Needed
- Interview 20+ families about current memory preservation habits
- Test automated call system with 10 elders (tech comfort, call quality)
- Validate pricing with target market (willingness to pay)
- Test threading concept (do families actually engage?)

### Design Priorities
- **Elder experience:** Zero learning curve, works over phone
- **Mobile apps:** Consumer-grade polish, podcast-app familiarity
- **Family tree:** Beautiful, emotional, shows progress
- **Notifications:** Not annoying, create anticipation

### Technical Proof-of-Concepts Needed
- Automated call system with smart prompts
- Real-time transcription quality and cost
- AI auto-titling (test GPT-4 prompt engineering)
- Threading UI/UX (nested comments in mobile)

---

## Next Steps

### Immediate Actions (Week 1-2)
1. **Validate demand:** Interview 10 target users (parents with aging parents)
2. **Technical feasibility:** Test Twilio automated call system
3. **AI testing:** Test transcription accuracy (Whisper vs. AssemblyAI)
4. **Competitive research:** Sign up for and test StoryWorth, Remento

### MVP Build (Month 1-3)
1. Design core user flows (Figma)
2. Build backend API and database
3. Integrate Twilio for automated calls
4. Build iOS app (prioritize over Android for MVP)
5. Build admin web dashboard
6. Implement AI pipeline (transcription + titling)
7. Recruit 50 beta families

### Beta Launch (Month 3-4)
1. Onboard beta families
2. Monitor metrics obsessively
3. Interview users weekly
4. Iterate on prompts and features
5. Validate retention mechanics

---

**Document End**

*This PRD is a living document and should be updated as we learn from users and validate assumptions.*
