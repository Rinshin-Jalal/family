# Psychology-Driven Onboarding Implementation Plan

## Overview
15-screen onboarding flow across 8 phases designed to drive subscriptions through emotion, psychology, and value demonstration.

**Core Philosophy:** Sell organization & transformation of chaotic memories into searchable, shareable wisdom.

---

## Phase 1: The Biological Imperative (The Hook)
**Goal:** Trigger instinct to preserve lineage. Frame problem as "Digital Chaos."

### Screen 1: The Digital Dust
**UI Components:**
- Phone scrolling animation (endless camera roll)
- Audio: overwhelming static → silence
- Headline: "You have the memories. You just can't find them."
- Subtext about digital noise
- CTA: "I want to organize my legacy"

**Technical Requirements:**
```swift
- AnimatedScrollView with simulated camera roll
- Audio overlay (static noise fade)
- Hero illustration component
- CTA with haptic feedback
```

---

## Phase 2: The Audit (The Quiz)
**Goal:** Diagnose "Digital Health" and reveal current method failures.

### Data Model
```swift
struct DigitalHealthQuiz {
    var accessibilityAnswer: AccessibilityAnswer  // Q1
    var aestheticAnswer: AestheticAnswer          // Q2
    var collaborationAnswer: CollaborationAnswer  // Q3
    var vulnerableAdvice: String                  // Q4 (free text)

    var healthScore: DigitalHealthGrade {
        // Calculate based on answers
    }
}

enum AccessibilityAnswer {
    case yesWritten           // A: Has it written down
    case scrollAudio          // B: Hours of audio to scroll
    case noIdea               // C: No idea where it is
}

enum AestheticAnswer {
    case screenshots          // A: Just screenshots/texts
    case photosNoWords        // B: Photos but no words
    case messyChats           // C: Hidden in messy chats
}

enum CollaborationAnswer {
    case siblingsHavePhotos   // A: Siblings have photos
    case parentsHaveStories   // B: Parents have untold stories
    case scatteredEverywhere  // C: Scattered across phones
}
```

### Screen 2: Accessibility Check
**Question:** "If your child asked, 'What did Grandpa say about love?' could you find the answer in 30 seconds?"

**UI:**
- Frustrated user illustration with "No results" search bar
- 3 option cards with icons
- Selection triggers: **Wisdom Search feature highlight**

### Screen 3: Aesthetic Gap
**Question:** "Do you have any beautiful mementos of your family's best advice?"

**UI:**
- Split view: ugly screenshot vs beautiful framed quote
- 3 option cards
- Selection triggers: **Quote JPG feature highlight**

### Screen 4: Collaboration Trap
**Question:** "Who holds the missing pieces of your family story?"

**UI:**
- Family member icons with red "X" overlays
- 3 option cards
- Selection triggers: **Allow Others to Add feature**

### Screen 5: The Vulnerability
**Question:** "What is the one piece of advice you never want to forget?"

**UI:**
- Elegant text input field
- Auto-save to state
- Psychology: Personal investment in output

---

## Phase 3: Analysis & Custom Plan
**Goal:** Build "Custom Plan" based on quiz. Sell result, not features.

### Screen 6: Analyzing Your Archive
**UI:**
- High-tech scanning animation
- Progress text: "Mapping digital clutter...", "Identifying lost wisdom..."
- Result: "We found a high risk of data loss"

**Technical:**
```swift
- Fake progress animation (2-3 seconds)
- Randomized "scanning" messages
- Transition to diagnosis
```

### Screen 7: The Diagnosis
**UI:**
- "Heritage Health" Report card (Grade: C+)
- Three findings:
  - ⚠️ Low Accessibility
  - ⚠️ Visual Decay
  - ⚠️ Incomplete History
- CTA: "Generate My Curation Plan"

**Diagnosis Algorithm:**
```swift
func generateDiagnosis(from quiz: DigitalHealthQuiz) -> Diagnosis {
    var findings: [Finding] = []

    // Check accessibility
    if quiz.accessibilityAnswer != .yesWritten {
        findings.append(.lowAccessibility)
    }

    // Check aesthetic
    if quiz.aestheticAnswer != .photosNoWords {
        findings.append(.visualDecay)
    }

    // Check collaboration
    if quiz.collaborationAnswer != .siblingsHavePhotos {
        findings.append(.incompleteHistory)
    }

    let grade = calculateGrade(from: findings)
    return Diagnosis(findings: findings, grade: grade)
}
```

---

## Phase 4: The Dream Transformation
**Goal:** Show "After" state using specific features.

### Screen 8: Magic Search (Wisdom Search)
**UI:**
- Split screen comparison
- Before: Scrolling "Voice Memo 1", "Voice Memo 2"...
- After: Type "Dad's advice on money" → instant audio clip plays
- Headline: "Turn your phone into a family genius"

**Technical:**
```swift
- Side-by-side comparison view
- Simulated search animation
- Audio playback demonstration
```

### Screen 9: Golden Nugget (Quote JPG)
**UI:**
- Magical transformation animation:
  1. Audio waveform of mom talking
  2. AI transcribes: "Happiness is a choice, not a result."
  3. Text stylizes into beautiful Quote Card
- Headline: "Turn moments into masterpieces"

**Technical:**
```swift
- 3-step animation sequence
- Text morphing effect
- Background style transitions
```

### Screen 10: Unified Vault (Allow Others to Add)
**UI:**
- "Digital Table" visualization
- Different hands (avatars) dropping photos/notes into glowing book
- Headline: "One family. One book."

**Technical:**
```swift
- Particle/drop animation
- Glowing book effect
- Multiple avatar system
```

---

## Phase 5: Scary Facts vs. The Savior
**Goal:** Juxtapose pain of "Digital Rot" with safety of App.

### Screen 11: The Reality (Scary)
**UI:**
- Dark, glitching visuals
- Statistics:
  - "Hard drives fail in 3-5 years"
  - "Links break. Clouds get deleted"
  - "If you can't search it, you don't really have it"
- Corrupted file icon

**Technical:**
```swift
- Dark mode forced
- Glitch animation effects
- Fade/transition to bright savior screen
```

### Screen 12: The Savior (Juxtaposition)
**UI:**
- Bright, clean, organized grid
- Headline: "Family+ makes your memories immortal"
- Comparison table:
  - Old Way: Messy folders, lost links
  - Family+ Way: Searchable wisdom, beautiful cards

**Technical:**
```swift
- Comparison card component
- Bright gradient backgrounds
- Smooth transition from dark screen 11
```

---

## Phase 6: App Review (Custom Plan)
**Goal:** Final confirmation of value.

### Screen 13: Your Custom Curation Plan
**UI:**
- Checklist tailored to user's quiz answers
- Headline: "This is your Legacy Protocol"
- 5 steps with icons:
  1. 📥 The Collect
  2. 🧠 The Extract
  3. 🖼️ The Polish
  4. 🔍 The Search
  5. 👨‍👩‍👧‍👦 The Invite

**Technical:**
```swift
struct CustomPlan {
    let steps: [PlanStep]
    let basedOnQuizResults: Bool

    init(from quiz: DigitalHealthQuiz) {
        // Customize steps based on user's answers
        steps = generatePersonalizedSteps(quiz)
    }
}
```

---

## Phase 7: Processing & Unlock
**Goal:** Build anticipation.

### Screen 14: Final Compilation
**UI:**
- Progress bar: "Preparing your Wisdom Search Engine"
- Animation messages:
  - "Optimizing search algorithms..."
  - "Designing your first Quote Card..."
  - "Securing your family vault..."
- Text: "Your family history is about to get organized"

**Technical:**
```swift
- Fake loading with real-feeling messages
- 3-5 second duration
- Smooth transition to paywall
```

---

## Phase 8: The Paywall
**Goal:** High contrast price vs value.

### Screen 15: The Investment
**UI:**
- Clean pricing card
- Headline: "Don't lose the stories that made you"
- Price: $4.99/month
- Value Juxtaposition:
  - Cost: "Less than one coffee per month"
  - Value: "A searchable, shareable, organized library of your family's soul"
- Feature Stack with ✅:
  - Unlimited Wisdom Search
  - Auto-Generated Quote JPGs
  - Smart Transcription
  - Family Invites
  - Permanent Cloud Vault
- Urgency Footer: "Every day you wait, more memories fade..."
- Primary CTA (Big & Green): "ORGANIZE MY LEGACY NOW"
- Secondary: "Restore Purchases"

**Technical:**
```swift
- RevenueCat integration for subscription
- A/B testing price points
- Analytics tracking (paywall views, conversion)
- Offer free trial option
```

---

## File Structure

```
familyplus/familyplus/Screens/Onboarding/
├── PsychologyOnboardingCoordinator.swift      // Main coordinator
├── PsychologyOnboardingContainerView.swift    // Container
├── PsychologyOnboardingModels.swift          // Data models
├── Screens/
│   ├── Phase1_Hook/
│   │   └── DigitalDustView.swift
│   ├── Phase2_Audit/
│   │   ├── AccessibilityCheckView.swift
│   │   ├── AestheticGapView.swift
│   │   ├── CollaborationTrapView.swift
│   │   └── VulnerabilityInputView.swift
│   ├── Phase3_Analysis/
│   │   ├── AnalyzingArchiveView.swift
│   │   └── DiagnosisView.swift
│   ├── Phase4_Transformation/
│   │   ├── MagicSearchView.swift
│   │   ├── GoldenNuggetView.swift
│   │   └── UnifiedVaultView.swift
│   ├── Phase5_Reality/
│   │   ├── DigitalRotView.swift
│   │   └── SaviorView.swift
│   ├── Phase6_Review/
│   │   └── CustomPlanView.swift
│   ├── Phase7_Processing/
│   │   └── FinalCompilationView.swift
│   └── Phase8_Paywall/
│       └── InvestmentPaywallView.swift
└── Components/
    ├── QuizOptionCard.swift
    ├── DiagnosisCard.swift
    ├── FeatureComparisonView.swift
    ├── SplitScreenComparison.swift
    └── ScanningAnimationView.swift
```

---

## Coordinator Logic

```swift
enum PsychologyOnboardingStep: Int, CaseIterable {
    // Phase 1: Hook
    case digitalDust = 0

    // Phase 2: Audit
    case accessibilityCheck = 1
    case aestheticGap = 2
    case collaborationTrap = 3
    case vulnerabilityInput = 4

    // Phase 3: Analysis
    case analyzingArchive = 5
    case diagnosis = 6

    // Phase 4: Transformation
    case magicSearch = 7
    case goldenNugget = 8
    case unifiedVault = 9

    // Phase 5: Reality
    case digitalRot = 10
    case savior = 11

    // Phase 6: Review
    case customPlan = 12

    // Phase 7: Processing
    case finalCompilation = 13

    // Phase 8: Paywall
    case investment = 14
}

final class PsychologyOnboardingCoordinator: ObservableObject {
    @Published var currentStep: PsychologyOnboardingStep = .digitalDust
    @Published var quizState = DigitalHealthQuiz()
    @Published var diagnosis: Diagnosis?
    @Published var customPlan: CustomPlan?
    @Published var isLoading = false

    // Navigation with validation
    func goToNextStep() {
        guard canProceed else { return }
        // Step progression logic
    }

    // Quiz answer handlers
    func setAccessibilityAnswer(_ answer: AccessibilityAnswer) {
        quizState.accessibilityAnswer = answer
        goToNextStep()
    }

    // Diagnosis generation
    func generateDiagnosis() {
        diagnosis = DiagnosisGenerator.generate(from: quizState)
    }

    // Custom plan generation
    func generateCustomPlan() {
        customPlan = CustomPlan(from: quizState, diagnosis: diagnosis!)
    }
}
```

---

## Analytics Tracking

```swift
enum OnboardingEvent {
    case screenView(step: PsychologyOnboardingStep)
    case quizAnswer(question: String, answer: String)
    case diagnosisGenerated(grade: String)
    case paywallViewed
    case purchaseAttempted
    case purchaseCompleted
    case onboardingCompleted(duration: TimeInterval)
}

// Track funnel
ValueAnalyticsService.shared.trackOnboardingEvent(.screenView(step: .digitalDust))
```

---

## Implementation Priority

1. **Phase 1 (Foundation)** - Models, Coordinator, Navigation
2. **Phase 2 (Quiz)** - Screens 1-5 with data collection
3. **Phase 3 (Analysis)** - Diagnosis algorithm and screens 6-7
4. **Phase 4 (Showcase)** - Feature demos (screens 8-10)
5. **Phase 5 (Emotion)** - Fear/relief screens (11-12)
6. **Phase 6 (Plan)** - Custom plan screen (13)
7. **Phase 7 (Buildup)** - Processing screen (14)
8. **Phase 8 (Close)** - Paywall with RevenueCat (15)

---

## Subscription Integration

```swift
import RevenueCat

class SubscriptionManager: ObservableObject {
    @Published var hasActiveSubscription = false

    func offerSubscription() {
        // Display paywall from Screen 15
    }

    func purchaseSubscription() async throws {
        // Handle $4.99/month purchase
    }
}
```

---

## Notes

- **Total Screens:** 15
- **Estimated Onboarding Time:** 3-5 minutes
- **Key Emotional Beats:** Fear of loss → Hope → Anticipation → Investment
- **Psychology Triggers:** Scarcity (digital rot), Social proof (family), Urgency (memories fading daily)
- **Value Focus:** Organization over storage, Transformation over collection
