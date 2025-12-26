

Here is the **Full Adaptive Design System** for StoryRide.

This document serves as the "Bible" for the UI. It defines how the app morphs its look and feel to serve the 4 specific personas while maintaining a unified brand identity.

---

## **1. DESIGN PRINCIPLES (THE SOUL)**

*   **Cinematic Over Clutter:** The UI is a frame for the content. We want users to feel like they are watching a movie about their family.
*   **Adaptive Intelligence:** The UI recognizes *who* is holding the device and adjusts itself automatically (Large text, Dark mode, Simplified nav).
*   **Dignified Playfulness:** We never make the app look "babyish." We use sophistication for teens/parents and *tactility* for children/elders.
*   **Typography-Led:** Words and fonts carry the emotion. The UI supports the text, it doesn't distract from it.

---

## **2. TYPOGRAPHY (THE VOICE)**

We use **SF Pro** (System) for UI and a **Serif (New York)** for Story Content.

| Token | Teen | Parent | Child | Elder |
| :--- | :--- | :--- | :--- | :--- |
| **Headline** | SF Pro Display<br>**Bold / 28pt**<br>*(Trendy, tight spacing)* | SF Pro Text<br>**Semibold / 24pt**<br>*(Clear, trustworthy)* | SF Pro Rounded<br>**Heavy / 32pt**<br>*(Playful, friendly)* | SF Pro Text<br>**Bold / 34pt**<br>*(Maximum legibility)* |
| **Body** | SF Pro Text<br>**Regular / 17pt**<br>*(Dark grey on black)* | SF Pro Text<br>**Regular / 17pt**<br>*(Black on white)* | SF Pro Rounded<br>**Medium / 22pt**<br>*(Easy to read)* | SF Pro Text<br>**Medium / 28pt**<br>*(Large type)* |
| **Story Text** | **New York Serif**<br>Italic / 20pt | **New York Serif**<br>Regular / 20pt | **SF Pro Rounded**<br>*(No Serif for kids)* | **SF Pro Text**<br>*(No Serif for elders)* |

---

## **3. COLOR PALETTE (THE MOOD)**

The base colors shift between Dark (Teen) and Light (Everyone else). The Accent remains consistent (Indigo) to maintain brand identity.

### **Base Colors**
| Token | Hex | Usage |
| :--- | :--- | :--- |
| `Ink Black` | `#000000` | Teen Background. |
| `Paper White` | `#FFFFFF` | Parent/Child Background. |
| `Warm Yellow` | `#FFF9C4` | Elder Background (High contrast warm tone). |
| `Surface Grey` | `#F2F2F7` | Cards/Modals (Light Mode). |
| `Dark Grey` | `#1C1C1E` | Cards/Modals (Dark Mode). |

### **Accent Colors (Brand Identity)**
| Token | Hex | Usage |
| :--- | :--- | :--- |
| `Brand Indigo` | `#5856D6` | Primary Buttons, Links, Active States. |
| `Soft Indigo` | `#E5E1FA` | Secondary backgrounds, tags. |
| `Alert Red` | `#FF3B30` | Stop recording, Delete, Errors. |

---

## **4. SPACING & LAYOUT (THE STRUCTURE)**

We use an **8pt Grid**.

| Token | Teen | Parent | Child | Elder |
| :--- | :--- | :--- | :--- | :--- |
| **Screen Padding** | 16px | 20px | 24px | 32px |
| **Card Radius** | 12px | 16px | 24px | 24px |
| **Button Height** | 44px (Standard) | 48px (Comfortable) | 80px (Giant) | 60px (Accessible) |
| **Touch Target** | Min 44x44pt | Min 48x48pt | Min 80x80pt | Min 60x60pt |

---

## **5. COMPONENT ADAPTATION (THE BRICKS)**

This is how the same UI component morphs.

### **A. The Navigation Bar**
*   **Teen:** Minimal. Floating glassmorphism bar at bottom. Icons only (no text).
*   **Parent:** Standard iOS Tab Bar. Clear text labels + Icons.
*   **Child:** **Hidden.** Navigation is handled by big on-screen arrows.
*   **Elder:** **Hidden.** One screen at a time. "Next" and "Back" buttons are huge text labels.

### **B. The "Record" Button (Primary Action)**
*   **Teen:** Thin outline circle. "Ghost" button. Fills with Indigo when recording.
*   **Parent:** Solid Indigo circle. Clean shadow.
*   **Child:** Giant Orange/Red solid circle with a "Pulse" animation. Icon is 2x size.
*   **Elder:** N/A (They use the phone).

### **C. The Story Card**
*   **Teen:** Full bleed image. Text overlay at bottom. Minimalist.
*   **Parent:** Card with white padding below image. Clean separation.
*   **Child:** Card with rounded corners (24px). Image takes up 80% of card. Text is huge and readable.
*   **Elder:** Single card centered on screen. Image is large. Text is auto-read (TTS).

---

## **6. MOTION (THE FEEL)**

*   **Teen:** **Snappy / Springy.** Physics-based transitions. Elements slide in quickly.
*   **Parent:** **Smooth / Ease-In-Out.** Calm, professional transitions.
*   **Child:** **Bouncy / Elastic.** Elements have "pop" animations. Feedback is exaggerated.
*   **Elder:** **Slow / Fade.** Elements gently fade in/out. No rapid movement (dizzying).

---

## **7. THE ADAPTIVE MATRIX (CHEAT SHEET)**

| **Property** | **Teen** | **Parent** | **Child** | **Elder** |
| :--- | :--- | :--- | :--- | :--- |
| **Background** | Black (`#000000`) | White (`#FFFFFF`) | White (`#FFFFFF`) | Warm Yellow (`#FFF9C4`) |
| **Text Color** | White (`#FFFFFF`) | Black (`#000000`) | Black (`#000000`) | Black (`#000000`) |
| **Font Family** | SF Pro + Serif | SF Pro + Serif | SF Rounded | SF Pro |
| **Primary Button** | Outline/Ghost | Solid Pill | Giant Circle | N/A |
| **Card Style** | Glass/Overlay | Clean/Border | Thick Border | Plain/Big |
| **Prompt Input** | Voice + Text | Voice + Text | **Voice Only (Audio Q)** | **Phone Call** |
| **Navigation** | Bottom Dock | Bottom Tab Bar | **Arrows/Linear** | **One Screen** |
| **Feedback** | Haptic + Subtle | Visual + Subtle | **Sound + Particle** | **Voice (Audio)** |

---

## **8. IMPLEMENTATION LOGIC (The "State" Object)**

In SwiftUI/React, this is managed by a `ThemeState`.

```swift
// Pseudo-code logic
switch(currentUser.role) {
    case .teen:
        backgroundColor = .black
        font = .system(.body)
        buttonStyle = .ghost
    case .parent:
        backgroundColor = .white
        font = .body
        buttonStyle = .filled
    case .child:
        backgroundColor = .white
        font = .roundedLarge
        buttonStyle = .giantCircle
        enableAudioPrompts = true
    case .elder:
        backgroundColor = .warmYellow
        font = .accessibleLarge
        hideNavigation = true
}
```

**This system ensures that while the "Data" (The Story) remains constant, the "Experience" is perfectly tailored to who is using the app at that specific moment.**