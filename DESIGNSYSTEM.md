

# Owl Library Design System

Here is the **Full Adaptive Design System** for StoryRide.

This document serves as the "Bible" for the UI. It defines how the app morphs its look and feel to serve users while maintaining the unified **Owl Library** brand identity — warm, scholarly, and inviting like a cozy reading nook.

---

## **1. DESIGN PRINCIPLES (THE SOUL)**

*   **Cinematic Over Clutter:** The UI is a frame for the content. We want users to feel like they are watching a movie about their family.
*   **Adaptive Intelligence:** The UI recognizes *who* is holding the device and adjusts itself automatically (Large text, Dark mode, Simplified nav).
*   **Dignified Playfulness:** We never make the app look "babyish." We use sophistication for teens/parents and *tactility* for children/elders.
*   **Typography-Led:** Words and fonts carry the emotion. The UI supports the text, it doesn't distract from it.
*   **Warm & Scholarly:** Inspired by our owl mascot, the aesthetic evokes a cozy library — warm browns, creamy papers, and rich accent colors from the owl's distinctive scarf.

---

## **2. TYPOGRAPHY (THE VOICE)**

We use **SF Pro** (System) for UI and a **Serif (New York)** for Story Content.

| Token | Dark Mode | Light Mode |
| :--- | :--- | :--- |
| **Headline** | SF Pro Display<br>**Bold / 16pt**<br>*(Trendy, tight spacing)* | SF Pro Text<br>**Semibold / 16pt**<br>*(Clear, trustworthy)* |
| **Body** | SF Pro Text<br>**Regular / 17pt**<br>*(Cream on espresso)* | SF Pro Text<br>**Regular / 17pt**<br>*(Espresso on cream)* |
| **Story Text** | **New York Serif**<br>Italic / 20pt | **New York Serif**<br>Regular / 20pt |

---

## **3. COLOR PALETTE (THE MOOD)**

The **Owl Library** palette is derived from our scholarly owl mascot — warm neutrals from the feathers and vibrant accents from the colorful scarf.

### **Base Colors (Warm Neutrals)**

| Token | Hex | Usage |
| :--- | :--- | :--- |
| `Espresso Dark` | `#1A1210` | Dark mode background. Rich, warm black. |
| `Cocoa Brown` | `#3D2B2B` | Dark mode cards/surfaces. |
| `Warm Tan` | `#C4A574` | Mid-tone accent. Owl body color. |
| `Soft Parchment` | `#F5E6D3` | Light mode cards/surfaces. Like aged paper. |
| `Ivory Cream` | `#FFF8F0` | Light mode background. Warm white. |

### **Scarf Accent Colors (Brand Identity)**

The three colors from the owl's scarf form our primary brand palette:

| Token | Hex | Usage |
| :--- | :--- | :--- |
| `Burgundy Red` | `#8B2942` | Primary accent (Light mode). Bold, expressive. |
| `Forest Green` | `#3D6B4F` | Secondary accent. Grounded, stable. |
| `Owl Gold` | `#D4A84A` | Primary accent (Dark mode). CTAs, highlights. From owl's eyes. |

### **Soft Accent Variants**

| Token | Hex | Usage |
| :--- | :--- | :--- |
| `Soft Burgundy` | `#F5E1E6` | Light burgundy tint for backgrounds, tags. |
| `Soft Green` | `#E1F0E6` | Light green tint for backgrounds, tags. |
| `Soft Gold` | `#FFF5E1` | Light gold tint for backgrounds, tags. |

### **Alert Colors**

| Token | Hex | Usage |
| :--- | :--- | :--- |
| `Alert Red` | `#C42B2B` | Stop recording, Delete, Errors. Warm-toned red. |

### **Storyteller Timeline Colors**

Each family member gets a distinct color on the story timeline:

| Token | Hex | Persona |
| :--- | :--- | :--- |
| `Storyteller Elder` | `#D4A84A` | Gold — Wise, warm |
| `Storyteller Parent` | `#3D6B4F` | Green — Grounded, stable |
| `Storyteller Teen` | `#8B2942` | Burgundy — Bold, expressive |
| `Storyteller Child` | `#C4946A` | Amber — Playful, warm |

---

## **4. SPACING & LAYOUT (THE STRUCTURE)**

We use an **8pt Grid**.

| Token | Dark Mode | Light Mode |
| :--- | :--- | :--- |
| **Screen Padding** | 16px | 20px |
| **Card Radius** | 12px | 16px |
| **Button Height** | 44px (Standard) | 48px (Comfortable) |
| **Touch Target** | Min 44x44pt | Min 48x48pt |

---

## **5. COMPONENT ADAPTATION (THE BRICKS)**

This is how the same UI component morphs across themes.

### **A. The "Record" Button (Primary Action)**
*   **Dark Mode:** Thin outline circle with gold accent. "Ghost" button. Fills with Owl Gold when recording.
*   **Light Mode:** Solid Burgundy circle. Clean shadow. Professional feel.

### **B. The Story Card**
*   **Dark Mode:** Full bleed image. Text overlay at bottom on espresso cards. Minimalist.
*   **Light Mode:** Card with parchment padding below image. Clean separation. Warm borders.

---

## **6. MOTION (THE FEEL)**

*   **Dark Mode:** **Snappy / Springy.** Physics-based transitions. Elements slide in quickly.
*   **Light Mode:** **Smooth / Ease-In-Out.** Calm, professional transitions.

---

## **7. THE ADAPTIVE MATRIX (CHEAT SHEET)**

| **Property** | **Dark Mode (Scholarly Night)** | **Light Mode (Cozy Library)** |
| :--- | :--- | :--- |
| **Background** | Espresso Dark (`#1A1210`) | Ivory Cream (`#FFF8F0`) |
| **Text Color** | Ivory Cream (`#FFF8F0`) | Espresso Dark (`#1A1210`) |
| **Secondary Text** | Warm Tan @ 70% (`#C4A574`) | Cocoa Brown @ 60% (`#3D2B2B`) |
| **Accent Color** | Owl Gold (`#D4A84A`) | Burgundy Red (`#8B2942`) |
| **Card Background** | Cocoa Brown (`#3D2B2B`) | Soft Parchment (`#F5E6D3`) |
| **Font Family** | SF Pro + Serif | SF Pro + Serif |
| **Primary Button** | Outline/Ghost (Gold) | Solid Pill (Burgundy) |
| **Card Style** | Glass/Overlay | Clean/Parchment |
| **Animation** | Spring (0.3s) | Ease-in-out (0.3s) |

---

## **8. IMPLEMENTATION LOGIC (The "State" Object)**

In SwiftUI, this is managed via `PersonaTheme` protocol and environment values.

```swift
// Theme selection
switch(selectedTheme) {
    case .dark:
        backgroundColor = .espressoDark    // #1A1210
        textColor = .ivoryCream            // #FFF8F0
        accentColor = .owlGold             // #D4A84A
        cardBackground = .cocoaBrown       // #3D2B2B
    case .light:
        backgroundColor = .ivoryCream      // #FFF8F0
        textColor = .espressoDark          // #1A1210
        accentColor = .burgundyRed         // #8B2942
        cardBackground = .softParchment    // #F5E6D3
}
```

---

## **9. BRAND MASCOT**

The **Scholarly Owl** serves as the app's mascot and brand foundation:

- **Character:** Warm, wise, approachable — wears reading glasses and a colorful scarf
- **Colors derived from:**
  - Feathers → Warm neutrals (espresso, cocoa, tan, cream)
  - Scarf → Brand accents (burgundy, forest green, gold)
  - Eyes → Owl Gold highlight color
- **Personality:** The owl represents the wisdom passed between generations, the warmth of family stories, and the cozy feeling of gathering to share memories.

---

**This system ensures that while the "Data" (The Story) remains constant, the "Experience" is perfectly tailored to the user's preference — whether they prefer the cozy warmth of a sunlit library or the intimate glow of a scholarly evening.**
