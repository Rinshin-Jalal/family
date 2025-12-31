# StoryRide - Quick Start Guide

## 🚀 Getting Started

### 1. Open the Project

```bash
cd /Users/rinshin/Code/code/familiy+
open familyplus/familyplus.xcodeproj
```

### 2. Build & Run

1. Select your target device (iPhone 15 Pro recommended)
2. Press `Cmd + R` to build and run
3. The app will launch with the Parent theme by default

### 3. Test Profile Switching

1. Tap the profile icon (top-right)
2. Select different personas to see UI transformations:
   - **Leo (Teen)** → Dark mode, minimalist
   - **Mom (Parent)** → Light mode, organized
   - **Mia (Child)** → Bright, giant buttons
   - **Grandma (Elder)** → High contrast, large text

## 🎨 Visual Guide

### Teen Mode
```
Background: Black
Style: Instagram/TikTok aesthetic
Navigation: Floating bottom bar (icons only)
Record Button: Thin outline circle
Layout: Full-screen vertical scroll
```

### Parent Mode
```
Background: White
Style: Organized dashboard
Navigation: Standard tab bar
Record Button: Solid indigo circle
Layout: Masonry grid
```

### Child Mode
```
Background: White
Style: Playful, tactile
Navigation: Hidden (arrows only)
Record Button: Giant orange circle (pulsing)
Layout: Single centered card
```

### Elder Mode
```
Background: Warm yellow
Style: Maximum legibility
Navigation: One screen at a time
Record Button: N/A (phone-based)
Layout: Minimal, centered
```

## 📱 Testing the 4 Main Screens

### 1. Hub (Home Feed)
**Location:** First tab / Main screen

**What to Test:**
- Teen: Swipe up/down through stories
- Parent: Scroll through masonry grid, check progress banner
- Child: Tap left/right arrows to navigate
- Elder: See single welcome screen

### 2. Studio (Creation)
**Trigger:** Tap the `+` button (or floating action button)

**What to Test:**
- Teen: See minimalist prompt + waveform when recording
- Parent: Edit prompt text, switch between record/type
- Child: Tap "Listen to Question" → Giant mic appears
- Elder: See "Call Me Now" phone interface

### 3. Family
**Location:** Second tab (Teen/Parent) or sticker icon (Child)

**What to Test:**
- Teen: See personal story gallery, "Share to Instagram" button
- Parent: View family stats, streak, progress bars
- Child: Collect stickers, see progress
- Elder: See minimal placeholder

### 4. Story Detail
**Trigger:** Tap any story card

**What to Test:**
- Color-coded timeline (different colors per speaker)
- Play/pause audio
- Reaction picker (bottom sheet)
- "Add Perspective" button (multiplayer)

## 🎯 Key Features to Demo

### 1. Instant Theme Switching
```
1. Open any screen
2. Tap profile switcher (top-right)
3. Select different persona
4. Watch entire UI transform instantly
```

### 2. Adaptive Components

**Story Cards:**
- Teen: Full bleed with overlay
- Parent: Clean card with padding
- Child: Giant rounded card
- Elder: Single centered card

**Buttons:**
- Teen: 44x44pt, ghost style
- Parent: 48x48pt, solid
- Child: 80x80pt, pulsing
- Elder: 60x60pt, simple

### 3. Multiplayer Timeline
```
Open Story Detail → See color-coded segments:
- 🟠 Orange = Grandma (Elder)
- 🔵 Blue = Dad (Parent)
- 🟣 Purple = Leo (Teen)
- 🟢 Green = Mia (Child)
```

### 4. Accessibility
```
1. Enable VoiceOver (Settings → Accessibility)
2. Navigate through app
3. All elements have proper labels/hints
```

## 🔧 Customization

### Change Default Profile

```swift
// In MainAppView.swift
init() {
    _currentProfile = State(
        initialValue: UserProfile(
            name: "Your Name",
            role: .teen, // Change this
            avatarEmoji: "🎸"
        )
    )
}
```

### Add Sample Stories

```swift
// In HubView.swift → Story.sampleStories
Story(
    title: "Your Story Title",
    storyteller: "Name",
    imageURL: nil,
    voiceCount: 1,
    timestamp: Date(),
    storytellerRole: .parent
)
```

### Modify Theme Colors

```swift
// In PersonaTheme.swift
struct DarkTheme: PersonaTheme {
    let accentColor = Color.brandIndigo // Change here
}
```

## 📋 Preview Guide

### View Previews in Xcode

All screens have built-in previews for all 4 personas:

```swift
// Example: HubView_Previews
Canvas → Select different previews:
- Teen Hub
- Parent Hub
- Child Hub
- Elder Hub
```

**To see previews:**
1. Open any View file
2. Press `Cmd + Option + Enter` (show canvas)
3. Click "Resume" if preview is paused

## 🐛 Troubleshooting

### Theme Not Updating
```swift
// Make sure view is wrapped in .themed()
MyView()
    .themed(currentTheme)
```

### Profile Switcher Not Showing
```swift
// Check toolbar placement in NavigationStack
.toolbar {
    ToolbarItem(placement: .navigationBarTrailing) {
        ProfileSwitcher(...)
    }
}
```

### Animations Not Working
```swift
// Use theme.animation for consistency
withAnimation(theme.animation) {
    // Your changes
}
```

## 📚 File Structure Quick Reference

```
Theme/
├── PersonaTheme.swift          ← Core theming system
├── Color+Extensions.swift      ← All colors
└── Font+Extensions.swift       ← All fonts

Components/
├── AdaptiveButton.swift        ← Buttons that adapt
├── StoryCard.swift             ← Story cards
└── ProfileSwitcher.swift       ← User switcher

Screens/
├── HubView.swift               ← Home feed
├── StudioView.swift            ← Creation
├── FamilyView.swift            ← Family/Stats
├── SettingsView.swift          ← User settings
└── StoryDetailView.swift      ← Story player

MainAppView.swift               ← Main container
familyplusApp.swift            ← Entry point
```

## 🎓 Learning Path

1. **Start Here:**
   - Open `PersonaTheme.swift` → Understand theming system
   - Open `StoryCard.swift` → See component adaptation

2. **Then Explore:**
   - `HubView.swift` → See 4 different layouts
   - `AdaptiveButton.swift` → See button adaptation

3. **Advanced:**
   - `MainAppView.swift` → Navigation logic
   - `StoryDetailView.swift` → Multiplayer timeline

## 🚀 Next Steps

1. **Run the app** → Test all 4 personas
2. **Read IMPLEMENTATION_GUIDE.md** → Deep dive
3. **Modify a theme** → Change colors/fonts
4. **Create a new screen** → Follow the pattern
5. **Add backend** → Connect to Supabase

---

**Need help? Check IMPLEMENTATION_GUIDE.md for detailed documentation**
