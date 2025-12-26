# UI Specifications & Design Details
# Family Memory App

**Version:** 1.0  
**Last Updated:** December 20, 2025

---

## Table of Contents

1. [Design System Specifications](#design-system-specifications)
2. [Component Library](#component-library)
3. [Animation & Transitions](#animation--transitions)
4. [Interaction Patterns](#interaction-patterns)
5. [Accessibility Specifications](#accessibility-specifications)
6. [Platform-Specific Guidelines](#platform-specific-guidelines)

---

## 1. Design System Specifications

### 1.1 Color System

#### Primary Colors
```
Gold/Amber (Heritage, Wisdom)
  - 50:  #FFFBEB
  - 100: #FEF3C7
  - 200: #FDE68A
  - 300: #FCD34D
  - 400: #FBBF24
  - 500: #F59E0B ← Primary
  - 600: #D97706
  - 700: #B45309
  - 800: #92400E
  - 900: #78350F
```

#### Secondary Colors
```
Navy (Trust, Stability)
  - 50:  #EFF6FF
  - 100: #DBEAFE
  - 200: #BFDBFE
  - 300: #93C5FD
  - 400: #60A5FA
  - 500: #3B82F6
  - 600: #2563EB
  - 700: #1D4ED8
  - 800: #1E40AF
  - 900: #1E3A8A ← Secondary
```

#### Accent Colors
```
Coral (Warmth, Connection)
  - Soft Coral: #FB7185
  - Used for: Hearts, reactions, warm CTAs

Sage Green (Success, Growth)
  - Sage: #10B981
  - Used for: Success states, milestones, growth indicators

Soft Red (Alert, Urgency)
  - Soft Red: #EF4444
  - Used for: Recording indicator, alerts, important actions
```

#### Neutral Colors
```
Warm Grays
  - 50:  #FAFAF9
  - 100: #F5F5F4
  - 200: #E7E5E4
  - 300: #D6D3D1
  - 400: #A8A29E
  - 500: #78716C
  - 600: #57534E
  - 700: #44403C
  - 800: #292524
  - 900: #1C1917
```

### 1.2 Typography

#### Font Families
```
Serif (Headings)
  - iOS: Georgia, "New York", serif
  - Android: "Noto Serif", Georgia, serif
  - Web: "Playfair Display", Georgia, serif
  
Sans-Serif (Body)
  - iOS: SF Pro, -apple-system, BlinkMacSystemFont, sans-serif
  - Android: "Roboto", "Noto Sans", sans-serif
  - Web: "Inter", -apple-system, BlinkMacSystemFont, sans-serif
```

#### Type Scale
```
Display (Hero headlines)
  - Size: 32pt / 40pt
  - Weight: Bold (700)
  - Line Height: 1.2
  - Usage: Landing page headlines, major section headers

H1 (Main headings)
  - Size: 28pt / 34pt
  - Weight: Bold (700)
  - Line Height: 1.25
  - Usage: Screen titles

H2 (Section headings)
  - Size: 22pt / 28pt
  - Weight: Semibold (600)
  - Line Height: 1.3
  - Usage: Card titles, section headers

H3 (Subsection headings)
  - Size: 18pt / 24pt
  - Weight: Semibold (600)
  - Line Height: 1.35
  - Usage: Story titles, component headers

Body Large
  - Size: 17pt / 22pt
  - Weight: Regular (400)
  - Line Height: 1.5
  - Usage: Primary body text, important descriptions

Body (Default)
  - Size: 15pt / 20pt
  - Weight: Regular (400)
  - Line Height: 1.5
  - Usage: Standard body text, descriptions

Body Small
  - Size: 13pt / 18pt
  - Weight: Regular (400)
  - Line Height: 1.45
  - Usage: Secondary information, metadata

Caption
  - Size: 11pt / 16pt
  - Weight: Regular (400)
  - Line Height: 1.4
  - Usage: Timestamps, helper text, labels
```

#### Elder-Friendly Type (Optional Mode)
```
All sizes increased by 20%:
  - H1: 34pt
  - Body: 18pt
  - Caption: 13pt
  
High contrast mode:
  - Text: #1C1917 (Gray 900)
  - Background: #FFFFFF
  - Minimum contrast ratio: 7:1 (AAA)
```

### 1.3 Spacing System

```
Base unit: 4pt

Spacing Scale:
  - xs:  4pt   (0.25rem)
  - sm:  8pt   (0.5rem)
  - md:  16pt  (1rem)   ← Base
  - lg:  24pt  (1.5rem)
  - xl:  32pt  (2rem)
  - 2xl: 48pt  (3rem)
  - 3xl: 64pt  (4rem)

Screen padding: 16pt (md)
Card padding: 16pt (md)
Section spacing: 24pt (lg)
Component spacing: 8pt (sm)
```

### 1.4 Border Radius

```
Roundness Scale:
  - sm:  4pt  - Small buttons, tags
  - md:  8pt  - Cards, inputs, standard buttons
  - lg:  12pt - Large cards, modals
  - xl:  16pt - Extra large cards
  - 2xl: 24pt - Hero cards
  - full: 999px - Pills, circular avatars, record button
```

### 1.5 Shadows & Elevation

```
Level 1 (Cards, subtle depth):
  iOS: shadow(color: #000, opacity: 0.05, offset: (0, 2), radius: 8)
  Android: elevation: 2dp
  
Level 2 (Floating elements):
  iOS: shadow(color: #000, opacity: 0.1, offset: (0, 4), radius: 12)
  Android: elevation: 4dp
  
Level 3 (Modals, overlays):
  iOS: shadow(color: #000, opacity: 0.15, offset: (0, 8), radius: 24)
  Android: elevation: 8dp
  
Level 4 (Floating action button):
  iOS: shadow(color: #000, opacity: 0.2, offset: (0, 12), radius: 32)
  Android: elevation: 12dp
```

---

## 2. Component Library

### 2.1 Buttons

#### Primary Button
```
Purpose: Main CTA, most important action
Size: 48pt height (min)
Padding: 16pt vertical, 24pt horizontal
Background: Gold-500 (#F59E0B)
Text: White, 17pt, Semibold
Border Radius: 8pt (md)
Shadow: Level 1

States:
  - Default: Gold-500
  - Hover: Gold-600
  - Active: Gold-700
  - Disabled: Gray-300, text Gray-500

Example:
┌────────────────────┐
│   Continue     →   │
└────────────────────┘
```

#### Secondary Button
```
Purpose: Alternative action, less emphasis
Size: 48pt height (min)
Padding: 16pt vertical, 24pt horizontal
Background: Transparent
Text: Navy-900, 17pt, Semibold
Border: 2pt solid Navy-900
Border Radius: 8pt (md)

States:
  - Default: Transparent bg, Navy-900 border
  - Hover: Navy-50 bg
  - Active: Navy-100 bg
  - Disabled: Gray-300 border, Gray-500 text

Example:
┌────────────────────┐
│   Go Back          │
└────────────────────┘
```

#### Text Button
```
Purpose: Tertiary action, minimal emphasis
Size: Auto height
Padding: 8pt vertical, 12pt horizontal
Background: Transparent
Text: Navy-700, 15pt, Medium

States:
  - Default: Navy-700
  - Hover: Navy-800, underline
  - Active: Navy-900
  - Disabled: Gray-400

Example:
  Skip for now
```

#### Icon Button
```
Purpose: Actions with icon only
Size: 44pt × 44pt (min touch target)
Icon: 24pt × 24pt
Background: Transparent or subtle fill
Border Radius: full (circular)

States:
  - Default: Gray-600 icon
  - Hover: Gray-800 icon, Gray-100 bg
  - Active: Navy-900 icon, Navy-100 bg

Example:
  ┌──────┐
  │  ⚙   │  ← Settings
  └──────┘
```

#### Record Button (Special)
```
Purpose: Primary recording action
Size: 80pt × 80pt
Background: Gradient (Red-500 to Red-600)
Icon: Microphone, 32pt
Border Radius: full (circular)
Shadow: Level 4 (elevated)

States:
  - Idle: Red gradient, mic icon
  - Recording: Pulsing animation, pause icon
  - Processing: Spinner animation

Visual:
      ╔══════════╗
      ║          ║
      ║    🎤    ║
      ║          ║
      ╚══════════╝
  [Pulsing glow when recording]
```

### 2.2 Story Card

```
Component: Story Card (Feed Item)

Dimensions:
  - Width: Screen width - 32pt (16pt padding each side)
  - Height: Auto (min 120pt)
  - Padding: 16pt all sides
  - Margin: 12pt between cards

Structure:
┌─────────────────────────────────────┐
│ ┌─────────┐                         │
│ │         │  My First Car           │← H3 (18pt, Semibold)
│ │ [Photo] │  by Grandpa Joe         │← Body Small (13pt)
│ │         │  12 min · Dec 20, 2025  │← Caption (11pt, Gray-500)
│ └─────────┘                         │
│                                     │
│ ▶ Play    💬 3 responses    ⋮      │← Actions
└─────────────────────────────────────┘

Elements:
  - Cover Image: 80pt × 80pt, border radius 8pt
  - Title: 2 lines max, ellipsis if overflow
  - Metadata: Single line, gray text
  - Actions: Icon buttons, 16pt spacing

Background: White
Border: 1pt solid Gray-200
Border Radius: 12pt (lg)
Shadow: Level 1

States:
  - Default: White bg
  - Unplayed: Gold-50 bg, Gold-500 accent border (left 4pt)
  - Pressed: Gray-50 bg
```

### 2.3 Input Fields

```
Component: Text Input

Dimensions:
  - Height: 48pt (min)
  - Padding: 12pt vertical, 16pt horizontal
  - Border: 1pt solid Gray-300
  - Border Radius: 8pt (md)

States:
  - Default: Gray-300 border, White bg
  - Focus: Navy-500 border (2pt), shadow
  - Filled: Navy-700 text
  - Error: Red-500 border, Red-50 bg
  - Disabled: Gray-200 bg, Gray-400 text

Label (above input):
  - Font: 15pt, Medium
  - Color: Gray-700
  - Margin bottom: 8pt

Helper text (below input):
  - Font: 13pt, Regular
  - Color: Gray-500 (default), Red-500 (error)
  - Margin top: 4pt

Example:
┌─────────────────────────────────────┐
│ Name                                │← Label
│ ┌─────────────────────────────────┐ │
│ │ John Johnson                    │ │← Input
│ └─────────────────────────────────┘ │
│ This is how family will see you     │← Helper
└─────────────────────────────────────┘
```

### 2.4 Avatar Component

```
Component: Avatar (Profile Photo)

Sizes:
  - xs:  24pt × 24pt (inline, metadata)
  - sm:  40pt × 40pt (list items)
  - md:  64pt × 64pt (cards, profiles)
  - lg:  96pt × 96pt (headers)
  - xl:  128pt × 128pt (profile pages)

Border Radius: full (circular)
Border: 2pt solid White (when overlapping)
Shadow: Level 1 (optional)

Fallback (no photo):
  - Background: Gradient based on name
  - Initials: White text, bold
  - Font size: 40% of avatar size

Status Indicator (optional):
  - Size: 25% of avatar size
  - Position: Bottom right, overlapping
  - Colors:
    - Green: Active (online/recent)
    - Yellow: Inactive
    - Gray: Invited/pending

Example:
    ╔═══════╗
    ║       ║
    ║  [👤] ║  ← Photo or initials
    ║     🟢║  ← Status indicator
    ╚═══════╝
```

### 2.5 Player Controls

```
Component: Audio Player Controls

Layout:
┌─────────────────────────────────────┐
│ Progress Bar                        │
│ ●─────────────○──────────────────○  │
│ 0:00         6:24              12:48│
│                                     │
│      ⏮   ◀◀   ▶️⏸   ▶▶   ⏭       │
│                                     │
│ 🔊 ───────○─────  1.0x  📱         │
└─────────────────────────────────────┘

Elements:

Progress Bar:
  - Height: 4pt
  - Background: Gray-200
  - Fill: Gold-500
  - Thumb: 16pt circle, White, shadow
  - Draggable

Timestamps:
  - Font: 11pt, Monospace
  - Color: Gray-600

Playback Buttons:
  - Size: 56pt × 56pt (center play/pause)
  - Size: 44pt × 44pt (all others)
  - Icon: 24pt × 24pt
  - Color: Navy-900

Volume Slider:
  - Width: 100pt
  - Height: 4pt
  - Same style as progress bar

Speed Control:
  - Tap to cycle: 1.0x → 1.25x → 1.5x → 2.0x → 0.5x → 0.75x → 1.0x
  - Font: 13pt, Semibold
```

### 2.6 Notification Badge

```
Component: Notification Count Badge

Dimensions:
  - Min size: 20pt × 20pt
  - Padding: 4pt horizontal (if text > 1 digit)
  - Font: 11pt, Bold
  - Border Radius: full

Colors:
  - Background: Red-500
  - Text: White

Position: Top right of parent element, 25% overlapping

Example:
    🔔 ← Bell icon
      (3) ← Badge
```

### 2.7 Empty State

```
Component: Empty State (No Content)

Layout:
┌─────────────────────────────────────┐
│                                     │
│                                     │
│             [Icon]                  │← 64pt icon, Gray-300
│                                     │
│         No Stories Yet              │← H2 (22pt, Semibold)
│                                     │
│   Your first story is being         │← Body (15pt, Gray-600)
│   recorded! Check back Wednesday.   │
│                                     │
│   ┌───────────────────────────┐     │
│   │     Get Started           │     │← Optional CTA
│   └───────────────────────────┘     │
│                                     │
└─────────────────────────────────────┘

Centered vertically and horizontally
Max width: 280pt
```

### 2.8 Modal / Dialog

```
Component: Modal Overlay

Backdrop:
  - Color: Black
  - Opacity: 0.5
  - Blur: 8pt (iOS) or dim (Android)

Modal Container:
  - Width: Screen width - 48pt (max 400pt)
  - Padding: 24pt
  - Background: White
  - Border Radius: 16pt (xl)
  - Shadow: Level 3

Layout:
┌─────────────────────────────────────┐
│  X                                  │← Close button (top right)
│                                     │
│  Are you sure?                      │← H2 title
│                                     │
│  This action cannot be undone.      │← Body text
│  All data will be lost.             │
│                                     │
│  ┌───────────────────────────────┐  │
│  │   Yes, Delete                 │  │← Primary (danger)
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │   Cancel                      │  │← Secondary
│  └───────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘

Animation:
  - Enter: Fade in + scale (0.9 → 1.0), 200ms
  - Exit: Fade out + scale (1.0 → 0.95), 150ms
```

---

## 3. Animation & Transitions

### 3.1 Screen Transitions

```
Navigation (Push/Pop):
  - Duration: 300ms
  - Easing: ease-in-out
  - iOS: Slide from right (push), slide to right (pop)
  - Android: Slide up (push), slide down (pop)

Modal Present/Dismiss:
  - Duration: 250ms
  - Easing: ease-out
  - Present: Slide up from bottom + fade in backdrop
  - Dismiss: Slide down + fade out backdrop

Tab Switch:
  - Duration: 200ms
  - Easing: ease-in-out
  - Cross-fade content, no slide
```

### 3.2 Component Animations

```
Button Press:
  - Scale: 0.95 (on press)
  - Duration: 100ms
  - Spring back on release

Card Tap:
  - Background color fade: 150ms
  - Scale: 0.98 (subtle)

Loading Spinner:
  - Rotation: 360° continuous
  - Duration: 1000ms
  - Easing: linear

Record Button Pulse (while recording):
  - Scale: 1.0 → 1.1 → 1.0
  - Opacity glow: 0.5 → 1.0 → 0.5
  - Duration: 1500ms
  - Loop: infinite

Skeleton Loading:
  - Shimmer effect: gradient slide
  - Duration: 1500ms
  - Loop: infinite

Pull to Refresh:
  - Elastic bounce
  - Spinner appears at threshold
```

### 3.3 Micro-interactions

```
Favorite Animation:
  - Icon: Outline → Filled
  - Color: Gray-600 → Red-500
  - Scale: 1.0 → 1.3 → 1.0
  - Duration: 400ms
  - Easing: spring

Notification Badge Appear:
  - Scale: 0 → 1.2 → 1.0
  - Duration: 300ms
  - Easing: spring
  - Optional: Haptic feedback (light impact)

Success Checkmark:
  - Draw path animation (stroke)
  - Duration: 500ms
  - Easing: ease-out
  - Scale pulse at end

Waveform Animation (while recording):
  - Bars: 5-7 vertical lines
  - Random height animation (20pt to 60pt)
  - Duration: 300ms per bar
  - Stagger: 50ms between bars
  - Loop: infinite
```

### 3.4 Page Load Animations

```
Skeleton Screen (Content Loading):
  - Show structure immediately
  - Shimmer effect on placeholder blocks
  - Fade to actual content when loaded
  
Fade-in List Items:
  - Stagger: 50ms per item
  - Fade + slight slide up (10pt)
  - Duration: 300ms each

Progressive Image Load:
  - Show gray placeholder
  - Blur-up: Load low-res → blur → high-res fade in
  - Duration: 400ms
```

---

## 4. Interaction Patterns

### 4.1 Gestures

```
Tap/Click:
  - Single tap: Primary action (play, open, select)
  - Tap target: Minimum 44pt × 44pt (iOS), 48dp (Android)

Long Press:
  - Duration threshold: 500ms
  - Action: Show context menu, additional options
  - Visual feedback: Haptic + scale slightly

Swipe:
  - Story card swipe right: Archive
  - Story card swipe left: Favorite
  - Threshold: 30% of card width
  - Visual: Card follows finger, show action icon

Pinch to Zoom (Family Tree):
  - Min scale: 0.5x
  - Max scale: 3.0x
  - Smooth interpolation

Pull to Refresh:
  - Threshold: 80pt pull distance
  - Show spinner at threshold
  - Release to trigger refresh
  - Haptic feedback at trigger point

Drag to Scrub (Audio Player):
  - Drag progress bar thumb
  - Show timestamp preview above thumb
  - Smooth scrubbing (no jumps)
```

### 4.2 Feedback Patterns

```
Visual Feedback:
  - Button press: Scale + color change
  - Loading: Spinner or skeleton
  - Success: Checkmark animation + green flash
  - Error: Shake animation + red flash

Haptic Feedback (iOS):
  - Light impact: Button tap, toggle
  - Medium impact: Record start/stop
  - Heavy impact: Error, important action
  - Success: Notification haptic

Audio Feedback (Optional):
  - Record start: Subtle "beep"
  - Record stop: Subtle "click"
  - Story published: Gentle chime
  - Error: Gentle "bonk" (system sound)

Toast Notifications:
  - Duration: 3 seconds (auto-dismiss)
  - Position: Bottom (above tab bar)
  - Style: Dark background, white text
  - Slide up animation
  - Swipe down to dismiss early
```

### 4.3 State Transitions

```
Loading State:
  - Show immediately (no delay)
  - Spinner or skeleton UI
  - Disable interaction

Empty State:
  - Illustration + message
  - Optional CTA
  - Helpful guidance

Error State:
  - Clear error message
  - Icon (⚠️ or ❌)
  - Action button ("Try Again", "Contact Support")
  - Don't lose user's data (preserve form input)

Success State:
  - Checkmark animation
  - Confirmation message
  - Auto-dismiss after 2-3 seconds
  - Optional: Confetti or celebration animation (for milestones)
```

---

## 5. Accessibility Specifications

### 5.1 VoiceOver / TalkBack Support

```
All interactive elements:
  - Accessibility label (clear, descriptive)
  - Accessibility hint (what happens when tapped)
  - Accessibility trait (button, link, header, etc.)

Example:
  Button: "Record"
  Label: "Record a story"
  Hint: "Double tap to start recording"
  Trait: Button

Images:
  - Alt text for all meaningful images
  - Decorative images: marked as such (ignored by screen readers)

Audio player:
  - Announce playback state changes
  - Announce time remaining
  - Scrubbing: Announce time as dragging
```

### 5.2 Dynamic Type Support

```
All text scales with system font size:
  - Min scale: 75% (Small)
  - Max scale: 200% (XXXL Accessibility)

Layout adjustments:
  - Single-column at largest sizes
  - Increased spacing between elements
  - Buttons grow vertically, not horizontally

Test at all sizes:
  - Small, Default, Large, XXL, XXXL (iOS)
  - Small, Default, Large, Largest (Android)
```

### 5.3 Color Contrast

```
WCAG AA Compliance (minimum):
  - Normal text: 4.5:1 contrast ratio
  - Large text (18pt+): 3:1 contrast ratio

WCAG AAA Compliance (preferred):
  - Normal text: 7:1 contrast ratio
  - Large text: 4.5:1 contrast ratio

High contrast mode:
  - All colors shifted to meet AAA
  - Borders added where needed
  - Background patterns removed

Color blindness:
  - Don't rely on color alone for meaning
  - Use icons + labels
  - Test with simulators
```

### 5.4 Keyboard Navigation (iPad/Web)

```
Tab order:
  - Logical reading order (top to bottom, left to right)
  - Skip navigation link (to main content)

Focus indicators:
  - Clear visual: 2pt outline, high contrast color
  - Never remove focus indicator

Keyboard shortcuts:
  - Space: Play/pause
  - ← →: Skip back/forward
  - Tab: Navigate elements
  - Enter: Activate button
  - Esc: Close modal
```

### 5.5 Reduce Motion

```
Respect system preference:
  - iOS: Settings > Accessibility > Motion > Reduce Motion
  - Android: Settings > Accessibility > Remove animations

When enabled:
  - Cross-fade instead of slide
  - Instant instead of spring
  - Static instead of pulse/shimmer
  - Maintain functional animations (e.g., loading spinner)
```

---

## 6. Platform-Specific Guidelines

### 6.1 iOS Specific

```
Navigation:
  - Large title on main screens
  - Back button: "< [Previous Screen Name]"
  - Swipe from left edge to go back

Status Bar:
  - Dark text on light backgrounds
  - Light text on dark backgrounds (if dark mode)

Tab Bar:
  - Bottom placement (fixed)
  - Icons + labels
  - Max 5 tabs

Safe Area:
  - Respect top notch and bottom home indicator
  - Use safe area insets for padding

System Features:
  - 3D Touch / Haptic Touch: Context menus on story cards
  - Face ID / Touch ID: For login
  - Siri shortcuts: "Hey Siri, record a family story"
  - Widgets: Show recent stories, upcoming calls
```

### 6.2 Android Specific

```
Navigation:
  - Hamburger menu or bottom nav
  - Back button: Hardware back button support
  - Up button in app bar: "←" (top left)

App Bar:
  - Top placement
  - Title + actions

Bottom Sheet:
  - Use for context menus, filters
  - Drag handle at top

Material Design:
  - FAB (Floating Action Button) for record action
  - Ripple effect on taps
  - Elevation for layers

System Features:
  - Adaptive icons: Provide various shapes
  - Quick settings tile: "Record Story"
  - Android Auto: Play stories in car
```

### 6.3 Web Specific

```
Responsive Breakpoints:
  - Mobile: < 640px
  - Tablet: 640px - 1024px
  - Desktop: > 1024px

Layout adjustments:
  - Mobile: Single column, bottom nav
  - Tablet: Two columns where appropriate, side nav
  - Desktop: Multi-column, persistent sidebar nav

Hover states:
  - Show on desktop (mouse)
  - Don't show on touch devices

Cursor:
  - Pointer on buttons and links
  - Default on text
  - Grab/grabbing on draggable elements

Browser compatibility:
  - Modern browsers (Chrome, Firefox, Safari, Edge)
  - Graceful degradation for older browsers
```

---

## 7. Performance Specifications

### 7.1 Loading Targets

```
Time to Interactive (TTI):
  - < 2 seconds on 4G
  - < 5 seconds on 3G

First Contentful Paint (FCP):
  - < 1 second

Image Loading:
  - Progressive JPEG / WebP
  - Lazy load below fold
  - Placeholder: Dominant color or blur-up

Audio Loading:
  - Stream (don't wait for full download)
  - Buffer: 30 seconds ahead
  - Cache downloaded stories
```

### 7.2 Animation Performance

```
Target: 60 FPS (16.67ms per frame)

Use GPU-accelerated properties:
  - transform (translate, scale, rotate)
  - opacity
  
Avoid:
  - Animating layout properties (width, height, top, left)
  - Complex box-shadows during animation

Optimize:
  - Use will-change hint (sparingly)
  - Composite layers for frequently animated elements
```

### 7.3 Offline Support

```
Critical features offline:
  - Play downloaded stories
  - Record new stories (queue for upload)
  - Browse cached content

Cache strategy:
  - Stories: Cache audio files when played/downloaded
  - Images: Cache on first load
  - Feed: Cache last 24 hours
  
Queue uploads:
  - New recordings saved locally
  - Auto-upload when online
  - Show queue status in UI
```

---

## 8. Component State Specifications

### 8.1 Button States (Complete Matrix)

```
Primary Button:
  ┌─────────────────────────────────────────────────────────┐
  │ State     │ Background   │ Text      │ Border  │ Shadow │
  ├───────────┼──────────────┼───────────┼─────────┼────────┤
  │ Default   │ Gold-500     │ White     │ None    │ Level 1│
  │ Hover     │ Gold-600     │ White     │ None    │ Level 1│
  │ Active    │ Gold-700     │ White     │ None    │ Level 1│
  │ Disabled  │ Gray-300     │ Gray-500  │ None    │ None   │
  │ Loading   │ Gold-500     │ Spinner   │ None    │ Level 1│
  └─────────────────────────────────────────────────────────┘
```

### 8.2 Input States (Complete Matrix)

```
Text Input:
  ┌─────────────────────────────────────────────────────────┐
  │ State     │ Border       │ Background│ Text      │ Label │
  ├───────────┼──────────────┼───────────┼───────────┼───────┤
  │ Empty     │ Gray-300 1pt │ White     │ Placehol. │ Gray-7│
  │ Focused   │ Navy-500 2pt │ White     │ Navy-900  │ Navy-7│
  │ Filled    │ Gray-300 1pt │ White     │ Navy-900  │ Gray-7│
  │ Error     │ Red-500 2pt  │ Red-50    │ Navy-900  │ Red-60│
  │ Disabled  │ Gray-200 1pt │ Gray-200  │ Gray-400  │ Gray-5│
  │ Read-only │ None         │ Gray-50   │ Gray-700  │ Gray-6│
  └─────────────────────────────────────────────────────────┘
```

### 8.3 Story Card States

```
Story Card:
  ┌─────────────────────────────────────────────────────────┐
  │ State     │ Background   │ Border    │ Indicator        │
  ├───────────┼──────────────┼───────────┼──────────────────┤
  │ Played    │ White        │ Gray-200  │ None             │
  │ Unplayed  │ Gold-50      │ Gold-500  │ 4pt left border  │
  │ Playing   │ Navy-50      │ Navy-500  │ Animated speaker │
  │ Pressed   │ Gray-50      │ Gray-300  │ None             │
  │ Favorite  │ White        │ Coral-300 │ ❤️ icon         │
  └─────────────────────────────────────────────────────────┘
```

---

## 9. Notification Design

### 9.1 Push Notification Format

```
New Story:
┌─────────────────────────────────────┐
│ [App Icon] Family Memories   now    │
│                                     │
│ 🎤 New story from Grandpa Joe       │
│ "My First Car"                      │
│                                     │
│ [Listen Now]                        │
└─────────────────────────────────────┘

Thread Response:
┌─────────────────────────────────────┐
│ [App Icon] Family Memories   2m ago │
│                                     │
│ 💬 Dad responded to Grandpa's story │
│ "I remember that car differently"   │
│                                     │
│ [See Response]                      │
└─────────────────────────────────────┘

Daily Prompt:
┌─────────────────────────────────────┐
│ [App Icon] Family Memories   9:00AM │
│                                     │
│ 💭 Today's prompt                   │
│ "Did Grandpa really leave Dad at    │
│  the bus station?"                  │
│                                     │
│ [Share Your Version]                │
└─────────────────────────────────────┘
```

### 9.2 In-App Notification (Toast)

```
┌─────────────────────────────────────┐
│ ✅ Story published!                 │
│ Your family will be notified        │
└─────────────────────────────────────┘
  ▲
  │ Slides up from bottom
  │ 3 second auto-dismiss
  │ Swipe down to dismiss early
```

---

## 10. Error Message Guidelines

### 10.1 Error Message Tone

```
Principles:
  - Clear and specific
  - Friendly, not technical
  - Actionable (tell user what to do)
  - Blame the system, not the user

Good examples:
  ✅ "We couldn't save your recording. Try again?"
  ✅ "Looks like you're offline. We'll upload when you're back online."
  ✅ "This audio file is too quiet. Try recording closer to your microphone."

Bad examples:
  ❌ "Error 500: Internal server error"
  ❌ "Invalid input"
  ❌ "Recording failed"
```

### 10.2 Error State Examples

```
Network Error:
┌─────────────────────────────────────┐
│            📡                       │
│                                     │
│    No Internet Connection           │
│                                     │
│  We'll save your recording and      │
│  upload it when you're back online. │
│                                     │
│  ┌───────────────────────────────┐  │
│  │   Got It                      │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘

Permission Error:
┌─────────────────────────────────────┐
│            🎤                       │
│                                     │
│    Microphone Access Needed         │
│                                     │
│  We need microphone access to       │
│  record your stories.               │
│                                     │
│  ┌───────────────────────────────┐  │
│  │   Open Settings               │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘

Storage Full:
┌─────────────────────────────────────┐
│            💾                       │
│                                     │
│    Storage Full                     │
│                                     │
│  Your device is out of space.       │
│  Free up some space and try again.  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │   Manage Storage              │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

---

## 11. Loading States

### 11.1 Skeleton Screens

```
Story Card Skeleton:
┌─────────────────────────────────────┐
│ ┌─────────┐  ▓▓▓▓▓▓▓▓▓▓▓▓          │
│ │░░░░░░░░░│  ▓▓▓▓▓▓                │
│ │░░░░░░░░░│  ▓▓▓▓▓▓▓▓▓              │
│ └─────────┘                         │
│                                     │
│ ▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓  ▓                │
└─────────────────────────────────────┘

Legend:
  ░ = Image placeholder (gray, no shimmer)
  ▓ = Text placeholder (shimmer effect)

Shimmer animation:
  - Gradient: Gray-200 → Gray-100 → Gray-200
  - Slide from left to right
  - Duration: 1.5s, infinite loop
```

### 11.2 Progress Indicators

```
Uploading Story:
┌─────────────────────────────────────┐
│                                     │
│    Uploading your story...          │
│                                     │
│    ▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░        │
│                                     │
│    65% complete                     │
│                                     │
└─────────────────────────────────────┘

Processing Story:
┌─────────────────────────────────────┐
│                                     │
│        [Spinner Animation]          │
│                                     │
│    Processing your story...         │
│    This takes about 2 minutes       │
│                                     │
└─────────────────────────────────────┘
```

---

**End of UI Specifications Document**

*These specifications should be implemented consistently across all platforms and regularly audited for compliance.*
