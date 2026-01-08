# STORYRD: MVP FEATURE PRIORITIZATION

## EVALUATION CRITERIA

| Criteria | Weight | Description |
|----------|--------|-------------|
| **Viral Worthy** | 30% | Will people share this? Creates FOMO? |
| **Retention Ready** | 30% | Will people come back daily/weekly? |
| **Simple** | 25% | Easy to build, understand, use? |
| **Easy Launch** | 15% | Can ship quickly? Minimal dependencies? |

## SCORING SYSTEM

```
Score: 1-5 for each criteria

VIRAL: 1=Never share, 5=Immediately share
RETENTION: 1=One-time use, 5=Can't stop using
SIMPLE: 1=Complex, 5=Dead simple
LAUNCH: 1=Months, 5=Days

WEIGHTED SCORE = (VIRAL × 0.3) + (RETENTION × 0.3) + (SIMPLE × 0.25) + (LAUNCH × 0.15)
```

---

## ALL FEATURES RANKED

### PRIORITY 1: HIGHEST IMPACT, QUICK WIN (Score 4.0+)

| Feature | Viral | Retention | Simple | Launch | **WEIGHTED** |
|---------|-------|-----------|--------|--------|--------------|
| **1. Quote Cards** | 5 | 3 | 5 | 5 | **4.55** |
| **2. Ask for Images** | 5 | 3 | 4 | 5 | **4.35** |
| **3. Family Polls** | 5 | 4 | 4 | 4 | **4.30** |
| **4. Year Map** | 5 | 5 | 3 | 4 | **4.25** |
| **5. Auto-tag Location** | 4 | 3 | 4 | 4 | **3.85** |

### PRIORITY 2: HIGH IMPACT, MODERATE EFFORT (Score 3.5-4.0)

| Feature | Viral | Retention | Simple | Launch | **WEIGHTED** |
|---------|-------|-----------|--------|--------|--------------|
| **6. AI Wisdom** | 4 | 5 | 2 | 3 | **3.65** |
| **7. Me vs. Family** | 5 | 3 | 4 | 3 | **3.60** |
| **8. Trivia Game** | 5 | 4 | 3 | 3 | **3.55** |
| **9. Story Art** | 5 | 2 | 2 | 3 | **3.25** |

### PRIORITY 3: GOOD FEATURES, LATER (Score 2.5-3.5)

| Feature | Viral | Retention | Simple | Launch | **WEIGHTED** |
|---------|-------|-----------|--------|--------|--------------|
| **10. Family Timeline** | 4 | 4 | 3 | 2 | **3.15** |
| **11. Time Capsule** | 4 | 5 | 2 | 2 | **3.05** |
| **12. Reenactments** | 5 | 2 | 2 | 3 | **2.95** |

### PRIORITY 4: POST-MVP (Score <2.5)

| Feature | Viral | Retention | Simple | Launch | **WEIGHTED** |
|---------|-------|-----------|--------|--------|--------------|
| **13. Family Yearbook** | 4 | 3 | 1 | 1 | **2.35** |

---

## MVP FEATURE BREAKDOWN (TOP 5)

### 1. QUOTE CARDS ⭐ HIGHEST PRIORITY

```
VIRAL: 5/5
├── 3-second hook
├── Beautiful, shareable
├── Emotional impact
└── One-tap save/share

RETENTION: 3/5
├── People check for new quotes
├── Daily/weekly value
└── Not daily habit

SIMPLE: 5/5
├── AI extracts quote (simple LLM)
├── Typography template (copy existing)
└── One-tap generate

LAUNCH: 5/5
├── Can ship in 1-2 days
├── No new UI patterns
└── Reuse existing components
```

**What to Build**:
```
┌─────────────────────────────────────────┐
│                                         │
│    "THE QUOTE"                          │
│                                         │
│    "The dress caught on fire            │
│     and everyone screamed—              │
│     except grandma. She just            │
│     kept dancing."                      │
│                                         │
│    — Grandma, 1978                      │
│                                         │
│  [💾 Save] [📤 Share] [👥 Family]       │
│                                         │
└─────────────────────────────────────────┘
```

**Implementation**:
- Day 1: LLM prompt for quote extraction
- Day 2: Quote card template (CSS/SwiftUI)
- Day 3: Share integration (iOS share sheet)
- Total: 3 days

---

### 2. ASK FOR IMAGES ⭐ HIGH PRIORITY

```
VIRAL: 5/5
├── Old photos = internet gold
├── "Found this in attic" = viral
├── Visual content = shares
└── "Then vs Now" = FOMO

RETENTION: 3/5
├── Encourages story creation
├── More visual = more engagement
└── Can become habit

SIMPLE: 4/5
├── Image upload (standard)
├── Display in story thread
└── Gallery view

LAUNCH: 5/5
├── Standard image picker
├── Cloud storage (existing)
└── Reuse photo UI components
```

**What to Build**:
```
┌─────────────────────────────────────────┐
│                                         │
│  📝 "Tell us about [prompt]"            │
│                                         │
│  📷 Add an image?                       │
│     ├── Old photo from that day         │
│     ├── Receipt/ticket from there       │
│     └── Screenshot of memory            │
│                                         │
│  [📤 Upload Image]                      │
│                                         │
│  [🎤 Start Recording]                   │
│                                         │
└─────────────────────────────────────────┘
```

**Implementation**:
- Day 1: Image upload flow
- Day 2: Image display in story thread
- Day 3: Gallery view + lightbox
- Total: 3 days

---

### 3. FAMILY POLLS ⭐ HIGH PRIORITY

```
VIRAL: 5/5
├── Generational debate = shares
├── "My grandma would NEVER" = viral
├── Results shareable
└── Creates conversation

RETENTION: 4/5
├── Daily engagement
├── Family competition
├── Can't miss results
└── Creates routine

SIMPLE: 4/5
├── Simple voting UI
├── Auto-generate from stories
└── Results visualization

LAUNCH: 4/5
├── Standard poll UI
├── AI generates poll questions
└── 1 week to build
```

**What to Build**:
```
┌─────────────────────────────────────────┐
│                                         │
│  📊 GENERATION POLL                     │
│                                         │
│  "Would you rather..."                  │
│                                         │
│  👵 Grandparents: Walk 5 miles          │
│     OR Drive                            │
│                                         │
│  👧 Kids: Walk 5 miles                  │
│     OR Drive                            │
│                                         │
│  👨 Parents: Walk 5 miles               │
│     OR Drive                            │
│                                         │
│  [VOTE]  [SEE RESULTS]                  │
│                                         │
└─────────────────────────────────────────┘
```

**Implementation**:
- Day 1-2: Poll UI (create, vote, results)
- Day 3-4: AI generates poll questions from stories
- Day 5: Push notifications for new polls
- Total: 5 days

---

### 4. YEAR MAP ⭐ HIGH PRIORITY

```
VIRAL: 5/5
├── "My family's journey" = shareable
├── Birth year search = viral
├── Visual timeline = beautiful
└── Location discovery = curiosity

RETENTION: 5/5
├── Daily curiosity ("What happened in 1978?")
├── Story discovery
├── Family journey tracking
└── Can't stop exploring

SIMPLE: 3/5
├── Timeline UI (moderate complexity)
├── Year picker (simple)
└── Map integration (moderate)

LAUNCH: 4/5
├── Timeline: 1 week
├── Map: 1 week (reuse MapKit)
├── Can launch with timeline only
└── Total: 2 weeks
```

**What to Build**:
```
┌─────────────────────────────────────────┐
│                                         │
│  🗺️  FAMILY TIMELINE MAP               │
│                                         │
│       1950      1978      2005      2024 │
│        ●─────────●─────────●─────────●  │
│        │         │         │         │  │
│     Grandma   Parents   Kids     Grandkids│
│     arrives   married   born     born    │
│                                         │
│  Tap year → Stories from that year      │
│  Tap place → Stories from that place    │
│                                         │
│  [🔍 Search: "1978"]  [📍 Search: "NYC"]│
│                                         │
└─────────────────────────────────────────┘
```

**Implementation**:
- Week 1: Timeline UI + Year picker
- Week 2: Map integration + Search
- Week 3: AI year context ("What happened in 1978")
- Total: 3 weeks

---

### 5. AUTO-TAG LOCATION ⭐ HIGH PRIORITY

```
VIRAL: 4/5
├── "Stories from my favorite spot"
├── Venue partnerships = reach
├── Location pages = discoverable
└── Less viral than others

RETENTION: 3/5
├── Encourages story creation
├── Location discovery
└── Not daily habit

SIMPLE: 4/5
├── Location picker (standard)
├── Place page template
└── Venue tagging

LAUNCH: 4/5
├── 1 week to build
├── Reuse existing UI
└── Can partner with venues
```

**What to Build**:
```
┌─────────────────────────────────────────┐
│                                         │
│  📍 WHERE DID THIS HAPPEN?              │
│                                         │
│  📍 Current Location: Detected          │
│     [Use This]  [Search]  [Skip]        │
│                                         │
│  🏠 PAST LOCATIONS                      │
│     ├── 123 Main St (5 stories)         │
│     ├── Grandma's House (12 stories)    │
│     └── Lepavillon NYC (3 stories)      │
│                                         │
│  [🎤 Continue Recording]                │
│                                         │
└─────────────────────────────────────────┘
```

**Implementation**:
- Day 1-2: Location picker + detection
- Day 3-4: Place pages
- Day 5: Venue partnerships (manual first)
- Total: 5 days

---

## IMPLEMENTATION ROADMAP

### PHASE 1: LAUNCH READY (Days 1-7)

| Day | Feature | Deliverable |
|-----|---------|-------------|
| 1-3 | Quote Cards | Auto-generate quote cards from stories |
| 4-5 | Ask for Images | Upload images with stories |
| 6-7 | Auto-tag Location | Location picker + place pages |

**After Phase 1**:
- Core app is viral-ready
- Shareable content available
- Location discovery working

---

### PHASE 2: ENGAGEMENT (Days 8-21)

| Week | Feature | Deliverable |
|------|---------|-------------|
| Week 2 | Family Polls | Daily polls, generational debates |
| Week 3 | Year Map | Timeline + year search |

**After Phase 2**:
- Retention features live
- Daily engagement loop
- Family journey tracking

---

### PHASE 3: DIFFERENTIATORS (Days 22-45)

| Week | Feature | Deliverable |
|------|---------|-------------|
| Week 4 | AI Wisdom | Ask family members questions |
| Week 5 | Me vs. Family | Generational comparisons |
| Week 6 | Trivia Game | Family trivia from stories |

**After Phase 3**:
- Full viral engine
- Strong retention
- Competitive differentiation

---

## FEATURE BY FEATURE ANALYSIS

### QUOTE CARDS (MVP DAY 1-3)

```
Technical Requirements:
├── LLM integration (existing)
├── Image generation (Canvas/PNG)
├── Share sheet (existing)
└── Storage (existing)

Dependencies:
└── None (reuse existing)

Risk Level: LOW
├── No new APIs
├── No complex UI
└── High impact
```

---

### ASK FOR IMAGES (MVP DAY 4-5)

```
Technical Requirements:
├── Image picker (iOS native)
├── Cloud storage (existing S3)
├── Image display (existing)
└── Gallery view (new)

Dependencies:
├── Photo library permission
└── S3 upload (existing)

Risk Level: LOW
├── Standard iOS functionality
└── Low technical risk
```

---

### FAMILY POLLS (MVP WEEK 2)

```
Technical Requirements:
├── Poll creation UI
├── Voting system
├── Results visualization
├── AI poll question generation
└── Push notifications

Dependencies:
├── AI (existing OpenAI)
├── Push notifications (existing)
└── Database (existing)

Risk Level: MEDIUM
├── New interaction pattern
├── Need AI prompt engineering
└── 1 week buffer
```

---

### YEAR MAP (MVP WEEK 3)

```
Technical Requirements:
├── Timeline UI
├── Year picker
├── Map integration (MapKit)
├── Search functionality
└── AI year context

Dependencies:
├── MapKit (iOS native)
├── Search (Elasticsearch/Algolia)
└── AI (existing)

Risk Level: MEDIUM
├── Complex UI
├── Map integration
└── 2 week buffer
```

---

### AUTO-TAG LOCATION (MVP WEEK 1-2)

```
Technical Requirements:
├── Location picker (CoreLocation)
├── Place pages
├── Venue search
├── Location database

Dependencies:
├── CoreLocation (iOS native)
└── Places API (Google/Apple)

Risk Level: LOW
├── Standard iOS APIs
└── Low technical risk
```

---

## VIRAL CONTENT STRATEGY BY PHASE

### Phase 1 Content (Days 1-7)

| Content Type | Platform | Example |
|--------------|----------|---------|
| Quote Cards | All | "Grandma's wisdom in one image" |
| Old Photos | TikTok/IG | "Found this in my parent's attic" |
| Location Stories | IG/FB | "Stories from [Venue]" |

### Phase 2 Content (Days 8-21)

| Content Type | Platform | Example |
|--------------|----------|---------|
| Poll Results | Twitter/FB | "Grandma vs Mom: Who would walk 5 miles?" |
| Year Timeline | All | "My family's journey through time" |
| Generational Debates | TikTok | "My 80-year-old grandma vs me" |

### Phase 3 Content (Days 22-45)

| Content Type | Platform | Example |
|--------------|----------|---------|
| AI Wisdom | Twitter | "What would grandma say about [topic]?" |
| Trivia Scores | All | "I got 9/10 on family trivia. Can you?" |
| Comparisons | TikTok | "Me at 8 vs Grandma at 8" |

---

## RETENTION ENGINE BY PHASE

### Phase 1 (Days 1-7)

```
Daily Hook:
├── New stories to listen
├── New quote cards to see
├── New images to explore
└── Location updates

Retention Mechanism:
├── Daily notification: "New story from grandma"
├── FOMO: "You're missing family updates"
└── Social: "React to today's stories"
```

### Phase 2 (Days 8-21)

```
Daily Hook:
├── New polls to vote
├── New year discoveries
├── Family competition
└── Can't miss results

Retention Mechanism:
├── Daily poll: "Vote before results"
├── Weekly challenge: "Complete 5 polls"
├── Family leaderboard
└── Streak: "7 days of voting"
```

### Phase 3 (Days 22-45)

```
Daily Hook:
├── New trivia to play
├── AI wisdom to discover
├── New comparisons to make
└── Challenge friends

Retention Mechanism:
├── Daily trivia challenge
├── AI conversation
├── Competition: "Beat your sibling's score"
└── Achievement: "Trivia Master"
```

---

## FINAL SCORECARD

### MVP Features (Ship in 21 days)

| # | Feature | Days | Viral | Retention | Launch Risk |
|---|---------|------|-------|-----------|-------------|
| 1 | Quote Cards | 3 | 5 | 3 | LOW |
| 2 | Ask for Images | 2 | 5 | 3 | LOW |
| 3 | Auto-tag Location | 5 | 4 | 3 | LOW |
| 4 | Family Polls | 5 | 5 | 4 | MEDIUM |
| 5 | Year Map | 7 | 5 | 5 | MEDIUM |

**Total: 22 days**

---

### Phase 3 Features (Ship in 45 days)

| # | Feature | Days | Viral | Retention | Launch Risk |
|---|---------|------|-------|-----------|-------------|
| 6 | AI Wisdom | 7 | 4 | 5 | MEDIUM |
| 7 | Me vs. Family | 5 | 5 | 3 | LOW |
| 8 | Trivia Game | 7 | 5 | 4 | MEDIUM |

**Total: 45 days**

---

### Post-MVP (After 45 days)

| # | Feature | Days | Why Later |
|---|---------|------|-----------|
| 9 | Story Art | 14 | AI image generation = complex |
| 10 | Reenactments | 10 | Video = storage + moderation |
| 11 | Family Timeline | 10 | Nice to have, not core |
| 12 | Time Capsule | 14 | Complex future logic |
| 13 | Family Yearbook | 21 | Print production = complex |

---

## SUMMARY: BUILD OR NOT BUILD

### BUILD FOR MVP (Priority 1-5)

| Feature | Why |
|---------|-----|
| **Quote Cards** | Highest viral potential, lowest effort |
| **Ask for Images** | Visual content, emotional, easy |
| **Auto-tag Location** | Discoverable, partnerships, simple |
| **Family Polls** | Retention engine, engagement, viral |
| **Year Map** | Retention killer, discovery, beautiful |

### BUILD FOR PHASE 2 (Priority 6-8)

| Feature | Why |
|---------|-----|
| **AI Wisdom** | High retention, unique differentiation |
| **Me vs. Family** | Viral content, simple to build |
| **Trivia Game** | Engagement, competition, shareable |

### BUILD POST-MVP (Priority 9-13)

| Feature | Why |
|---------|-----|
| **Story Art** | Beautiful but AI-heavy |
| **Reenactments** | Video = complexity |
| **Family Timeline** | Nice to have after core |
| **Time Capsule** | Complex future logic |
| **Family Yearbook** | Print production = complex |

---

## ONE-LINE SUMMARIES

**For Investors**:
```
"22 days to launch: quote cards, photos, location, polls, year map
= viral family content engine"
```

**For Engineers**:
```
"Week 1: Quote cards + Images + Location
Week 2: Polls
Week 3: Year Map
Ship. Iterate."
```

**For Users**:
```
"Share beautiful quotes, upload old photos, tag locations,
vote on generational debates, explore your family's journey.
All in 22 days."
```

---

