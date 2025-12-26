
### **1. The Shared Skeleton (The Foundation)**
*   **Layout:** A vertical feed of "Story Cards."
*   **Art Style:** "Memphis Minimal" or "Abstract Art" (Friendly, geometric, artistic).
*   **Typography:** Sans-Serif for UI (Clean), Serif for Stories (Classy).

---

### **2. The 4 Personas (The Experience)**

#### **A. The Teen (16-22): "The Aesthetic Curator"**
*   **Theme:** **Dark Mode** (Deep Black).
*   **Vibe:** Instagram/BeReal. High contrast, sleek, minimal.
*   **Text:** Serif fonts (looks like a magazine).
*   **Input:** Voice + Text. They type captions.
*   **Key Feature:** "Export to Stories." (They care about how it looks on their socials).

#### **B. The Parent (25-45): "The Organizer"**
*   **Theme:** **Light Mode** (Off-white).
*   **Vibe:** Airbnb/Notion. Organized, clean, feeling of "Digital Vault."
*   **Text:** Clear Sans-Serif. High readability.
*   **Input:** Voice + Text + Management (Editing prompts, adding members).
*   **Key Feature:** "Family Dashboard" (Managing the account).

#### **C. The Child (3-12): "The Explorer"**
*   **Theme:** **Bright & Tactile** (White background, but with **Large, Colorful Buttons**).
*   **Crucial Change:** **Audio-First.**
    *   Children often can't read the prompts. The app *reads the prompt to them* with a friendly voice.
*   **Interaction:** **One Tap.**
    *   Huge "Microphone" button.
    *   No editing. No typing. Record -> Done -> See Picture.
*   **Key Feature:** "Listen to the Question" button.

#### **D. The Elder (70+): "The Listener"**
*   **Theme:** **High Contrast Light Mode** (Yellow/Paper backgrounds).
*   **Vibe:** Large print, dignity, simplicity.
*   **Interaction:** **Zero Navigation.**
    *   They land on a screen with **One Giant Card**.
    *   No scrolling lists.
*   **Input:** **Phone Call Only.** (They do not use the app screen).

---

### **3. The "Mode Switcher" (How it works technically)**
Since a family often shares an iPad or a phone, we need a way to swap skins instantly.

**The "Profile Toggle" (Top Right of App):**
Instead of "Settings," we have a **User Switcher** (like Netflix).
*   Tap Avatar -> Dropdown: "Dad (Parent)", "Leo (Teen)", "Mia (Kid)", "Grandma (Phone)".
*   When you select **"Mia (Kid)"**, the entire app UI morphs:
    1.  Dark Mode turns to White.
    2.  Text size gets bigger.
    3.  Prompts turn into Audio buttons.
    4.  Navigation bars get simplified (hide "Settings").

---

### **4. Revised Component: The "Kid Prompt Card"**
This is the specific design change to accommodate Children without ruining the aesthetic.

**Teen/Parent View:**
> *Text Display:* "What was your favorite toy growing up?"
> *Button:* [Record Answer]

**Child View (Same Data, Different Skin):**
> *Visual:* An Icon of a Toy (or AI Image of a toy).
> *Action:* A Big **"Listen" Button** (Speaker Icon).
> *Flow:*
    1.  Kid taps "Listen."
    2.  Friendly AI Voice asks: *"What was your favorite toy?"*
    3.  Big "Record" Button appears.
    4.  Kid records.
    5.  App confetti/success animation (The only "gamified" part, kept subtle).

---

### **5. Summary of UI Differences**

| Element | **Teen** | **Parent** | **Child** | **Elder** |
| :--- | :--- | :--- | :--- | :--- |
| **Background** | Black (#000000) | Off-White (#F5F5F7) | White (#FFFFFF) | Warm Yellow (#FFF9C4) |
| **Text** | Serif (Classy) | Sans (Clean) | Sans (Big) | Sans (Huge) |
| **Input** | Voice + Text | Voice + Text | **Voice Only** | Phone Call |
| **Prompts** | Read text | Read text | **Listen to Audio** | N/A (Spoken on phone) |
| **Navigation** | Bottom Tab Bar | Bottom Tab Bar | **Hidden (Linear)** | N/A |

### **6. The Visual "Unifier"**
The one thing that ties all 4 groups together is the **AI Art Style**.
*   If the AI art is "Abstract and Geometric," it looks **Cool** to the Teen, **Modern** to the Parent, **Interesting** to the Child (shapes/colors), and **Clear** to the Elder (recognizable objects).

