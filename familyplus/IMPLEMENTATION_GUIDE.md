# StoryRide - Adaptive UI Implementation Guide

## 🎨 Overview

StoryRide is a multi-generational storytelling platform featuring a revolutionary **Adaptive UI System** that morphs the entire interface based on the user's persona (Teen, Parent, Child, Elder).

## 📁 Project Structure

```
familyplus/
├── Theme/
│   ├── PersonaTheme.swift          # Core theming system & protocol
│   ├── Color+Extensions.swift      # Design system colors
│   └── Font+Extensions.swift       # Typography system
├── Components/
│   ├── AdaptiveButton.swift        # Adaptive button components
│   ├── StoryCard.swift             # Adaptive story cards
│   └── ProfileSwitcher.swift       # Netflix-style profile switcher
├── Screens/
│   ├── HubView.swift               # Home feed (4 layouts)
│   ├── StudioView.swift            # Creation page (4 layouts)
│   ├── ProfileView.swift           # Profile/Stats (4 layouts)
│   └── StoryDetailView.swift      # Story detail with timeline
├── MainAppView.swift               # Main app container
└── familyplusApp.swift            # App entry point
```

## 🎭 The Adaptive Theme System

### Architecture

The adaptive UI system is built on three core principles:

1. **Protocol-Based Theming** - All themes conform to `PersonaTheme` protocol
2. **Environment Propagation** - Themes propagate through `@Environment`
3. **Component Adaptation** - Components read theme and adapt automatically

### PersonaTheme Protocol

```swift
protocol PersonaTheme {
    var role: PersonaRole { get }

    // Visual properties
    var backgroundColor: Color { get }
    var textColor: Color { get }
    var accentColor: Color { get }

    // Typography
    var headlineFont: Font { get }
    var bodyFont: Font { get }

    // Spacing
    var screenPadding: CGFloat { get }
    var cardRadius: CGFloat { get }

    // Motion
    var animation: Animation { get }

    // Features
    var showNavigation: Bool { get }
    var enableAudioPrompts: Bool { get }
}
```

### The 4 Personas

#### 1. Teen Theme (16-22)
**Aesthetic:** Dark mode, minimalist, Instagram-style

```swift
TeenTheme()
- Background: #000000 (Ink Black)
- Accent: #5856D6 (Brand Indigo)
- Font: SF Pro Display Bold + New York Serif
- Motion: Snappy/Springy (0.3s spring)
- Navigation: Floating glassmorphism bar
```

**Key Features:**
- Full-screen story cards (TikTok-style)
- Ghost record button (thin outline)
- Waveform visualizer when recording
- Share to Instagram functionality

#### 2. Parent Theme (25-45)
**Aesthetic:** Light mode, organized, dashboard-style

```swift
ParentTheme()
- Background: #FFFFFF (Paper White)
- Accent: #5856D6 (Brand Indigo)
- Font: SF Pro Semibold
- Motion: Smooth ease-in-out (0.3s)
- Navigation: Standard iOS Tab Bar
```

**Key Features:**
- Masonry grid (Pinterest-style)
- Progress tracking
- Prompt editing capability
- Family stats and streaks

#### 3. Child Theme (3-12)
**Aesthetic:** Bright, tactile, audio-first

```swift
ChildTheme()
- Background: #FFFFFF (Paper White)
- Accent: #FF9500 (Playful Orange)
- Font: SF Pro Rounded Heavy (32pt)
- Motion: Bouncy/Elastic (0.4s spring)
- Navigation: Hidden (linear flow with arrows)
```

**Key Features:**
- Single card storybook mode
- Audio prompts read aloud
- Giant buttons (80x80pt touch targets)
- Confetti celebrations
- Sticker reward system

#### 4. Elder Theme (70+)
**Aesthetic:** High contrast, large text, phone-based

```swift
ElderTheme()
- Background: #FFF9C4 (Warm Yellow)
- Accent: #5856D6 (Brand Indigo)
- Font: SF Pro Bold (34pt headlines)
- Motion: Slow fade (0.5s ease)
- Navigation: Hidden (one screen)
```

**Key Features:**
- Minimal UI (phone-based interaction)
- Maximum legibility (34pt headlines, 28pt body)
- No complex navigation
- Text-to-speech auto-read

## 🚀 Usage

### Applying Themes

```swift
// Apply theme to any view
MyView()
    .themed(TeenTheme())

// Access theme in view
struct MyView: View {
    @Environment(\.theme) var theme

    var body: some View {
        Text("Hello")
            .font(theme.headlineFont)
            .foregroundColor(theme.textColor)
    }
}
```

### Profile Switching

The Profile Switcher (top-right) allows instant theme switching:

```swift
ProfileSwitcher(
    currentProfile: $currentProfile,
    profiles: profiles
)
```

**When a user switches profiles:**
1. Theme updates via `@Environment`
2. All views automatically re-render with new theme
3. Animations transition smoothly
4. Components adapt (buttons resize, colors change, etc.)

## 🎯 Component Adaptation Examples

### Adaptive Buttons

```swift
RecordButton(isRecording: isRecording) {
    // Action
}

// Teen: Ghost outline circle
// Parent: Solid circle with shadow
// Child: Giant pulsing circle (80x80pt)
// Elder: Standard (60x60pt)
```

### Story Cards

```swift
StoryCard(story: story) {
    // Navigate to detail
}

// Teen: Full bleed, text overlay
// Parent: Card with padding, clean separation
// Child: 24px rounded, 80% image, huge text
// Elder: Single centered card, auto-read
```

## 📱 The 4 Main Screens

### 1. HubView (Home Feed)

**Teen:** Infinite vertical scroll (TikTok)
- Full-screen story cards
- Swipe up/down navigation
- Minimal top bar

**Parent:** Masonry Grid (Pinterest)
- 2-column grid layout
- Progress banner at top
- Standard navigation

**Child:** Storybook Mode
- Single centered card
- Giant "Listen" button
- Left/right arrows only

**Elder:** Voice Home
- Large icon and text
- Single "Start" button
- Minimal interaction

### 2. StudioView (Creation Page)

**Teen:** Minimalist
- Prompt text + record button
- Waveform visualizer
- Hold-to-record

**Parent:** Prompt Manager
- Editable prompt
- Type or record option
- Recording timer

**Child:** Magic Mic
- "Listen to Question" button
- Giant red mic button
- Confetti on completion

**Elder:** Phone Interface
- "Call Me Now" button
- Clear instructions
- Phone-based recording

### 3. ProfileView

**Teen:** "My Aesthetic"
- 3-column gallery grid
- Story count stats
- Share to Instagram

**Parent:** "Family Stats"
- Streak counter
- Total memories
- Progress bars
- Invite/upgrade buttons

**Child:** "Sticker Book"
- Earned stickers display
- Locked stickers (grayed)
- Progress bar
- Collection grid

**Elder:** Minimal
- Placeholder screen
- Phone-based interaction message

### 4. StoryDetailView

**Shared Features:**
- Color-coded timeline (Orange=Elder, Blue=Parent, Purple=Teen, Green=Child)
- Reaction system (❤️🔥👏😂😮)
- "Add Perspective" button (multiplayer)

**Teen/Parent:**
- Full transcription
- Multiple segments visible
- Waveform timeline
- Share button

**Child:**
- Large image
- Giant play button
- Audio-only

**Elder:**
- Text read aloud
- Simple controls
- Maximum legibility

## 🎨 Design System Tokens

### Colors

```swift
// Base Colors
Color.inkBlack        // #000000 - Teen background
Color.paperWhite      // #FFFFFF - Parent/Child background
Color.warmYellow      // #FFF9C4 - Elder background
Color.surfaceGrey     // #F2F2F7 - Cards (light mode)
Color.darkGrey        // #1C1C1E - Cards (dark mode)

// Accent Colors
Color.brandIndigo     // #5856D6 - Primary accent
Color.softIndigo      // #E5E1FA - Secondary
Color.alertRed        // #FF3B30 - Errors/stop
Color.playfulOrange   // #FF9500 - Child accent

// Storyteller Colors (Timeline)
Color.storytellerOrange  // Elder segments
Color.storytellerBlue    // Parent segments
Color.storytellerPurple  // Teen segments
Color.storytellerGreen   // Child segments
```

### Typography

```swift
// Adaptive Fonts
Font.adaptiveHeadline(for: theme)
Font.adaptiveBody(for: theme)
Font.adaptiveStory(for: theme)

// Specific Fonts
Font.Teen.headline        // SF Pro Display Bold 28pt
Font.Parent.headline      // SF Pro Semibold 24pt
Font.Child.headline       // SF Pro Rounded Heavy 32pt
Font.Elder.headline       // SF Pro Bold 34pt
```

### Spacing (8pt Grid)

```swift
theme.screenPadding    // 16-32px depending on persona
theme.cardRadius       // 12-24px
theme.buttonHeight     // 44-80px
theme.touchTarget      // 44-80px (WCAG compliant)
```

## ♿ Accessibility

### Built-in Support

- **VoiceOver:** All components have accessibility labels/hints
- **Dynamic Type:** Fonts scale with user preferences
- **Touch Targets:** Minimum 44x44pt (Child: 80x80pt)
- **Color Contrast:** WCAG AA compliant
- **Reduce Motion:** Respects system setting
- **Haptic Feedback:** Configurable per persona

### Example Usage

```swift
Button("Record") { }
    .accessibilityLabel("Start Recording")
    .accessibilityHint("Double tap to record your story")
```

## 🎬 Animations & Motion

### Motion Profiles

```swift
// Teen: Snappy, springy
Animation.spring(response: 0.3, dampingFraction: 0.7)

// Parent: Smooth, professional
Animation.easeInOut(duration: 0.3)

// Child: Bouncy, exaggerated
Animation.spring(response: 0.4, dampingFraction: 0.6)

// Elder: Slow, gentle
Animation.easeInOut(duration: 0.5)
```

### Haptic Feedback

```swift
if theme.enableHaptics {
    let impact = UIImpactFeedbackGenerator(
        style: theme.role == .child ? .heavy : .light
    )
    impact.impactOccurred()
}
```

## 🔧 Extending the System

### Adding a New Persona

1. **Add enum case:**
```swift
enum PersonaRole {
    case teen, parent, child, elder
    case grandparent // New!
}
```

2. **Create theme:**
```swift
struct GrandparentTheme: PersonaTheme {
    let role: PersonaRole = .grandparent
    // Implement all protocol requirements
}
```

3. **Update factory:**
```swift
static func theme(for role: PersonaRole) -> PersonaTheme {
    switch role {
    case .grandparent:
        return GrandparentTheme()
    // ...
    }
}
```

4. **Add to navigation:**
Update MainAppView with new navigation logic

### Adding a New Screen

1. **Create view:**
```swift
struct NewScreen: View {
    @Environment(\.theme) var theme

    var body: some View {
        Group {
            switch theme.role {
            case .teen:
                TeenNewScreen()
            case .parent:
                ParentNewScreen()
            // ...
            }
        }
    }
}
```

2. **Create persona-specific layouts:**
Each layout adapts to its theme automatically

## 📊 Performance Considerations

- **Theme Switching:** Instant via `@Environment` updates
- **Animations:** GPU-accelerated SwiftUI animations
- **Memory:** Themes are structs (value types)
- **Re-renders:** Only affected views re-render on theme change

## 🎯 Best Practices

1. **Always use theme properties:**
   ```swift
   ✅ Text("Hello").font(theme.headlineFont)
   ❌ Text("Hello").font(.headline)
   ```

2. **Test all 4 personas:**
   ```swift
   #Preview {
       MyView()
           .themed(TeenTheme())
   }
   ```

3. **Respect accessibility:**
   - Use semantic colors
   - Support Dynamic Type
   - Provide accessibility labels

4. **Follow motion profiles:**
   - Use `theme.animation` for consistency
   - Respect `enableHaptics` flag

## 🚦 Next Steps

1. **Backend Integration:**
   - Connect to Supabase
   - Implement authentication
   - Store user profiles

2. **Audio Features:**
   - TTS for prompts (Child/Elder)
   - Recording with visualization
   - Audio playback

3. **Multiplayer:**
   - Real-time updates
   - Push notifications
   - "Add Perspective" flow

4. **Social:**
   - Instagram export
   - Story sharing
   - Reaction system

## 📚 Resources

- [Apple HIG](https://developer.apple.com/design/human-interface-guidelines/)
- [SF Symbols](https://developer.apple.com/sf-symbols/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Accessibility Guidelines](https://developer.apple.com/accessibility/)

---

**Built with ❤️ following Apple's Human Interface Guidelines**
