# App Store Connect Complete Setup Guide - Family+

This guide walks through **EVERY** field and section you need to fill out manually in App Store Connect.

---

## 📋 Prerequisites Checklist

Before starting:
- [ ] Apple Developer Account enrolled ($99/year)
- [ ] App created in App Store Connect
- [ ] Bundle ID registered in Developer Portal
- [ ] Xcode project configured with correct Bundle ID
- [ ] Privacy Policy URL (host your policy online)
- [ ] Support URL (website or email)
- [ ] App screenshots prepared (see dimensions below)

---

## 🎯 Step 1: Create App in App Store Connect

### Navigation
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click **My Apps** in the sidebar
3. Click **+** button (top left)
4. Select **New App**

### Required Fields

| Field | Value | Notes |
|-------|-------|-------|
| **Platform** | iOS | Choose iOS |
| **Name** | Family+ | This is public-facing name |
| **Primary Language** | English | Can add later |
| **Bundle ID** | com.yourcompany.familyplus | Must match Xcode exactly |
| **SKU** | FAMILYPLUS001 | Unique ID for your internal tracking |

**Bundle ID Setup (if not exists)**:
1. Go to [Certificates, IDs & Profiles](https://developer.apple.com/account/resources/identifiers/list)
2. Click **+** to create new Bundle ID
3. Select **App IDs** → **App**
4. Enter **Description**: Family+ App
5. Enter **Bundle ID**: `com.yourcompany.familyplus`
6. Select capabilities:
   - ✅ In-App Purchase (if needed later)
   - ✅ Push Notifications (if needed later)
   - ✅ Background Modes
7. Click **Continue** → **Register**

---

## 🎯 Step 2: App Information Section

**Navigation**: App Store Connect → Your App → App Information

### 2.1 Basic Information

| Field | Value | Required |
|-------|-------|----------|
| **Name** | Family+ | ✅ Yes |
| **Subtitle** | Preserve Family Stories & Wisdom | ✅ Yes (30 char max) |
| **Privacy Policy URL** | https://yourdomain.com/privacy | ✅ Yes |
| **Support URL** | https://yourdomain.com/support | ✅ Yes |
| **Marketing URL** | https://yourdomain.com | Optional |
| **App Store Privacy URL** | https://yourdomain.com/privacy | ✅ Yes |

**Subtitle Examples** (30 characters max):
- "Preserve Family Stories & Wisdom" (31 chars ❌)
- "Preserve Family Stories" (23 chars ✅)
- "Family Stories & Memories" (26 chars ✅)
- "Your Family's Voice & Wisdom" (29 chars ✅)

### 2.2 Category

**Primary Category**: Social Networking

**Secondary Category** (optional):
- Lifestyle
- Photo & Video

**You might also like** (optional):
- Select similar apps for discovery

---

## 🎯 Step 3: Age Rating

**Navigation**: App Store Connect → Your App → Age Rating

### Complete the Age Rating Questionnaire

Answer **YES** to items that apply to your app:

#### Content - Objectable content
- **Graphic sexual content and nudity**: No
- **Profanity or crude humor**: No
- **Mature/Suggestive themes**: No
- **Horror/Fear themes**: No
- **Violence**: No
- **Violence against realistic characters**: No
- **Sexual violence and nonconsensual sexual content**: No

#### Content - Graphic content
- ** cartoon/fantasy violence**: No
- **Realistic violence**: No
- **Prolonged graphic or sadistic realistic violence**: No
- **Graphic sexual content and nudity**: No

#### Content - Other
- **Profanity or crude humor**: No
- **Behavior that could be considered imitable**: No
- **Gambling/Contests**: No
- **Unrestricted web access**: No
- **Gambling/Contests**: No

#### Apple's Content - Other
- **Unrestricted web access**: No
- **Gambling/Contests**: No

#### Age Rating Result

For Family+, you should get:
- **Rating**: 4+ ( ages 4 and up )
- **Reasons**: No objectionable content

---

## 🎯 Step 4: Pricing and Availability

**Navigation**: App Store Connect → Your App → Pricing and Availability

### 4.1 Price

| Field | Value |
|-------|-------|
| **Price** | Free |
| **Price Schedule** | Same price in all countries/regions |

### 4.2 Availability

| Field | Value |
|-------|-------|
| **Distribution** | All countries/regions (or select specific) |
| **Future Availability Date** | Leave blank (available immediately) |

### 4.3 Content Rights & Territories

| Field | Value | Notes |
|-------|-------|-------|
| **Content Rights** | Worldwide | Or select specific territories |
| **Territories** | All territories available | Unless content restricted |

### 4.4 App Content Distribution

| Field | Value |
|-------|-------|
| **Custom product pages** | Create later (optional) |
| **App Promotion** | Enabled (recommended) |

---

## 🎯 Step 5: App Privacy

**Navigation**: App Store Connect → Your App → App Privacy

### 5.1 Privacy Details

You'll need to complete the privacy questionnaire. For Family+:

#### Data Collection

| Data Type | Collected | Purpose |
|-----------|-----------|---------|
| **Contact Info** | ✅ Yes (email) | Account creation, authentication |
| **Health & Fitness** | ❌ No | - |
| **Financial Info** | ❌ No | - |
| **Location** | ❌ No | - |
| **Sensitive Info** | ❌ No | - |
| **Contacts** | ❌ No | - |
| **User Content** | ✅ Yes (audio, photos) | Stories, memories |
| **Browsing History** | ❌ No | - |
| **Search History** | ❌ No | - |
| **Identifiers** | ✅ Yes (User ID) | Analytics |
| **Usage Data** | ✅ Yes | App analytics |
| **Diagnostics** | ✅ Yes (crash logs) | Crash reporting |

#### Data Types to Report

**Contact Info**:
- Email address
- Name (optional)

**User Content**:
- Audio recordings
- Photos/videos
- Text content

**Identifiers**:
- User ID

**Usage Data**:
- Product interaction
- Crash logs

#### Data Linking
- **Linked to user**: ✅ Yes (account-based data)
- **Tracking**: ❌ No (no third-party tracking)

#### Data Purpose

- **App Functionality**: Account management, story storage
- **Analytics**: Understanding app usage
- **Product Personalization**: Customizing experience
- **Developer's Advertising or Marketing**: None

### 5.2 Privacy Policy URL

**Required**: https://yourdomain.com/privacy

Your policy must cover:
- What data you collect
- Why you collect it
- How you use it
- With whom you share it
- Data retention policies
- User rights (access, deletion, export)

---

## 🎯 Step 6: Prepare for Submission

**Navigation**: App Store Connect → Your App → iOS App → Prepare for Submission

### 6.1 Screenshots

**Required Screenshots** (minimum 3, maximum 10 per device size):

#### iPhone 6.7" Display (iPhone 14 Pro Max, 15 Pro Max)
- **Size**: 1290 x 2796 pixels
- **Format**: PNG or JPEG
- **Required**: 3-10 screenshots

**Screenshot Ideas**:
1. **Hub View**: Show main screen with family stories
2. **Record Audio**: Show recording interface
3. **Capture Memory**: Show story capture sheet
4. **Story Detail**: Show story playback
5. **Family View**: Show family members
6. **Wisdom Collection**: Show wisdom quotes
7. **Settings**: Show profile/settings
8. **Onboarding**: Show welcome flow

#### iPhone 6.5" Display (iPhone XS Max, 11 Pro Max)
- **Size**: 1242 x 2688 pixels
- **Required**: 3-10 screenshots

#### iPhone 5.5" Display (iPhone 8 Plus, 6s Plus)
- **Size**: 1242 x 2208 pixels
- **Required**: 3-10 screenshots

**Design Tips**:
- Use device frames (optional but professional)
- Show real app UI
- Highlight key features
- No status bar (use clean screenshots)
- Consistent style across all screenshots
- Show user benefits, not just features

### 6.2 App Preview Videos (Optional)

**Specifications**:
- **Length**: 15-30 seconds
- **Format**: .mov
- **Codecs**: ProRes, H.264, or H.265
- **Resolution**: Same as screenshots (1290 x 2796 for 6.7")

**App Preview Content Ideas**:
1. **Hook**: Problem statement (0-3s)
2. **Solution**: Show app solving it (3-15s)
3. **Features**: Quick feature walkthrough (15-25s)
4. **Call to Action**: Download now (25-30s)

### 6.3 App Information

| Field | Value | Character Limit |
|-------|-------|-----------------|
| **Name** | Family+ | 30 chars |
| **Subtitle** | Your Family's Voice & Wisdom | 30 chars |
| **Description** | [See below] | 4000 chars |

#### Description Template

```
Family+ preserves your family's stories, wisdom, and voice across generations.

CAPTURE MEMORIES EFFORTLESSLY
• Record audio stories with prompts
• Upload photos with context
• Add text memories and reflections
• Capture wisdom from elders

REPLAY ANYTIME
• Listen to family stories
• View photo memories
• Read wisdom and advice
• Share with family members

FOR THE WHOLE FAMILY
• Grandparents can call in stories
• Parents preserve childhood moments
• Kids learn family history
• Everyone stays connected

PRIVACY FIRST
• Family-only access
• Secure cloud storage
• Your data, your control

Start preserving your family legacy today.

Terms: https://yourdomain.com/terms
Privacy: https://yourdomain.com/privacy
Support: https://yourdomain.com/support
```

### 6.4 Keywords

**Keywords**: family, stories, memories, wisdom, grandparents, oral history, voice recorder, photo album, family tree, genealogy, heritage, legacy, elders

**Character Limit**: 100 characters (excluding commas)

**Strategy**: Use relevant search terms users might use

### 6.5 Promotional Text

**Promotional Text** (170 character max):
```
Preserve your family's voice, stories, and wisdom across generations. Record, replay, and share family memories forever.
```

### 6.6 Category

| Field | Value |
|-------|-------|
| **Primary** | Social Networking |
| **Secondary** | Photo & Video |

### 6.7 Content Rights

**Confirm**:
- [ ] I own or have exclusive rights to all content
- [ ] This app is not a spam copy
- [ ] No third-party content without permission

### 6.8 Export Compliance

**Answer for Family+**:
- **Encryption**: Yes (HTTPS)
- **Export Laws**: Compliant
- **Country of origin**: Your country

### 6.9 Advertising Identifier (IDFA)

**Answer for Family+**:
- **Do you use IDFA?**: No
- **Attribution**: None
- **Tracking**: None

---

## 🎯 Step 7: Build Information

**Navigation**: App Store Connect → Your App → iOS App → Builds

### 7.1 Upload Build

1. **In Xcode**:
   - Open `familyplus.xcodeproj`
   - Select "Any iOS Device"
   - Product → Archive
   - Wait for archive to complete

2. **In Archive Organizer**:
   - Select your archive
   - Click "Distribute App"
   - Select "App Store Connect"
   - Select "Automatically manage signing"
   - Click "Upload"
   - Wait for upload and processing

3. **In App Store Connect**:
   - Refresh the page
   - Your build should appear
   - Select the build for submission

### 7.2 Version Information

| Field | Value |
|-------|-------|
| **Version** | 1.0 |
| **Build Number** | 1 (auto-increment) |
| **Compatibility** | Requires iOS 16.0 or later |

### 7.3 Release Notes

```
Version 1.0 - Initial Release

Features:
• Record and preserve family audio stories
• Upload photos with family memories
• Capture wisdom and advice from elders
• Family member management
• Story playback and sharing
• Value extraction from stories
• Privacy-first family storage

Thank you for using Family+ to preserve your family legacy!
```

---

## 🎯 Step 8: App Store Review Information

**Navigation**: App Store Connect → Your App → iOS App → App Store Review

### 8.1 Review Information

| Field | Value | Notes |
|-------|-------|-------|
| **Login Required** | Yes | Demo account required |
| **User Name** | familyplus-demo@example.com | Test account |
| **Password** | [Provide demo password] | Test account |
| **Demo Instructions** | See below | How to test app |

### 8.2 Demo Account Setup Instructions

**Provide in "Demo Account Information" field**:

```
Demo Account Setup:

1. Launch app
2. Click "Sign Up with Apple" (using sandbox Apple ID)
3. Complete onboarding flow
4. Create first family or join existing
5. Test story capture: Tap "+" → "Capture Memory"
6. Test audio: Select "Voice" → Record sample story
7. Test photo: Select "Photo" → Upload sample photo
8. Test playback: Go to Hub → Tap story card → Play audio
9. Test family: Go to Family → Invite member
10. Test settings: Go to Settings → View profile

Test Credentials:
- No password required (Apple OAuth)
- Test data will be in "Demo Family"
- All features fully functional

Notes for Review:
- App requires Apple ID for authentication
- All data is sample/family-friendly content
- No in-app purchases
- No third-party tracking
- Family-only social networking
```

### 8.3 Review Notes (Optional)

```
Review Notes for Family+:

Family+ is a family-centric social network for preserving stories and wisdom across generations.

Key Features:
• Audio story recording with AI-generated prompts
• Photo memory capture with context
• Wisdom extraction from family conversations
• Family member management and invites
• Privacy-first, family-only access

Design Philosophy:
• Minimal friction story capture
• Emphasis on elder accessibility
• Value-based content organization
• Cross-generational connection

Technical Notes:
• Backend: Cloudflare Workers
• Database: Supabase PostgreSQL
• Storage: Cloudflare R2
• Authentication: Supabase Auth (Apple OAuth)
• Background jobs: Trigger.dev v3

No features require special hardware beyond standard iOS devices.

All UI components follow Apple Human Interface Guidelines.

Thank you for reviewing Family+!
```

---

## 🎯 Step 9: Final Checklist Before Submission

**Navigation**: App Store Connect → Your App → iOS App → Add for Review

### Required Items Checklist

- [ ] **App Information** filled out completely
- [ ] **Age Rating** questionnaire completed
- [ ] **Pricing and Availability** configured
- [ ] **App Privacy** details completed
- [ ] **Screenshots** uploaded (minimum 3 per device)
- [ ] **App Preview** videos (optional but recommended)
- [ ] **Description** written
- [ ] **Keywords** added
- [ ] **Promotional Text** added
- [ ] **Support URL** provided
- [ ] **Privacy Policy URL** provided
- [ ] **Build** uploaded and selected
- [ ] **Version Information** complete
- [ ] **Release Notes** written
- [ ] **Demo Account** information provided
- [ ] **Export Compliance** answered
- [ ] **Content Rights** confirmed
- [ ] **Advertising Identifier** answered

---

## 🎯 Step 10: Submit for Review

**Final Steps**:

1. **Review all sections**:
   - Go through each tab one more time
   - Verify all required fields are complete
   - Check for any warnings or errors

2. **Click "Add for Review"**:
   - App Store Connect → Your App → iOS App
   - Click "Add for Review" button (top right)
   - Review summary page

3. **Confirm Submission**:
   - Click "Submit for Review"
   - You'll receive confirmation email

4. **Wait for Review**:
   - Typical review time: 1-3 days
   - You'll get email with decision
   - Check app status in App Store Connect

---

## 📊 Review Status Timeline

| Status | Description | Duration |
|--------|-------------|----------|
| **Waiting for Review** | In queue | 1-2 days |
| **In Review** | Being reviewed | 1-3 days |
| **Pending Developer Release** | Approved, waiting for you to release | Instant |
| **Ready for Sale** | Live in App Store | After you release |
| **Rejected** | Fix issues and resubmit | See rejection email |

---

## 🔍 Common Rejection Reasons & Fixes

### Rejection: "Guideline 2.1 - Performance"

**Issue**: App crashes or doesn't work
**Fix**:
- Test on multiple physical devices
- Add crash reporting (Firebase Crashlytics)
- Fix all bugs before submission
- Test on both iPhone and iPad

### Rejection: "Guideline 2.3 - Performance"

**Issue**: App is incomplete or has placeholder content
**Fix**:
- Remove all TODO placeholders
- Ensure all features work
- Add sample content if needed
- Complete onboarding flow

### Rejection: "Guideline 4.0 - Design"

**Issue**: App looks like a website template
**Fix**:
- Use native iOS components
- Follow Human Interface Guidelines
- Show iOS-specific features
- Avoid web-like UI

### Rejection: "Guideline 5.1.1 - Data Collection"

**Issue**: Privacy issues
**Fix**:
- Complete privacy questionnaire accurately
- Add privacy policy URL
- Explain all data collection
- Add user data deletion in app

### Rejection: "Guideline 4.2 - Minimum Functionality"

**Issue**: App doesn't do enough
**Fix**:
- Add more features
- Ensure app provides value
- Avoid simple app wrappers

---

## 📞 Support Resources

**Apple Resources**:
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Developer Forums](https://developer.apple.com/forums/)

**Contact Apple**:
- Technical support: Contact in App Store Connect
- Account issues: 1-800-633-2152 (US)

---

## ✅ Pre-Submission Testing Checklist

Before submitting, test everything:

**On iPhone**:
- [ ] App launches without crash
- [ ] Authentication works
- [ ] Can record audio story
- [ ] Can upload photo
- [ ] Can play back audio
- [ ] Can view story details
- [ ] Can invite family member
- [ ] Settings page loads
- [ ] All screens navigate properly
- [ ] App works in background
- [ ] Push notifications work (if enabled)
- [ ] Deep links work
- [ ] Offline mode graceful

**On iPad** (if supporting):
- [ ] Layout looks good
- [ ] All features work
- [ ] No UI issues

**Edge Cases**:
- [ ] Poor network connection
- [ ] No network connection
- [ ] Server errors handled
- [ ] Large file uploads
- [ ] Memory pressure
- [ ] Low battery mode
- [ ] Background audio

---

**Last Updated**: 2026-01-12
**Good luck with your submission! 🚀**
