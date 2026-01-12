# iOS App Deployment Guide - Family+

## Prerequisites

- Apple Developer Account ($99/year)
- Xcode installed on Mac
- App Store Connect access
- Distribution certificate
- Provisioning profiles

---

## Phase 1: Pre-Deployment Checklist

### 1.1 Code Signing

```bash
# Open project in Xcode
open familyplus.xcodeproj

# Configure signing in Xcode:
# - Target: familyplus
# - Signing & Capabilities
# - Team: Select your development team
# - Signing Certificate: Automatically manage signing
```

### 1.2 Required Capabilities

Add in Xcode under **Signing & Capabilities**:

- **Background Modes**:
  - Audio, AirPlay, and Picture in Picture
  - Background processing
- **Microphone Usage Description**
- **Photo Library Usage Description**
- **Camera Usage Description**

```swift
// Info.plist keys (automatically added via Xcode)
NSMicrophoneUsageDescription = "Family+ needs access to your microphone to record family stories.";
NSPhotoLibraryUsageDescription = "Family+ needs access to your photos to add them to family memories.";
NSCameraUsageDescription = "Family+ needs access to your camera to capture new photos.";
```

---

## Phase 2: Environment Configuration

### 2.1 Update API Base URL

```bash
# Edit familyplus/Services/APIService.swift
# Update line 33:

// Production
private let API_BASE_URL = "https://your-worker-url.workers.dev"

// Or use environment-specific configuration
#if DEBUG
private let API_BASE_URL = "http://localhost:8787"
#else
private let API_BASE_URL = "https://your-worker-url.workers.dev"
#endif
```

### 2.2 Configure Supabase

```bash
# Edit familyplus/Services/SupabaseService.swift
# Update with your production credentials:

let supabaseURL = "https://your-project.supabase.co"
let supabaseKey = "your-anon-key"
```

---

## Phase 3: App Store Connect Setup

**⚠️ IMPORTANT**: This section requires manual configuration of **EVERY** field in App Store Connect.

**📖 See Complete Guide**: `APP_STORE_CONNECT_GUIDE.md` - This has detailed step-by-step instructions for every single field you need to fill out.

### 3.1 Quick Overview

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. **My Apps** → **+** → **New App**
3. Fill in basic app information
4. Complete **ALL** required sections (see detailed guide)

### 3.2 Required Sections (All Must Be Complete)

- ✅ App Information (name, subtitle, category)
- ✅ Age Rating (questionnaire - get 4+ rating)
- ✅ Pricing and Availability
- ✅ **App Privacy** (detailed data collection disclosure)
- ✅ Screenshots (minimum 3 per device size)
- ✅ Description, keywords, promotional text
- ✅ Privacy Policy URL
- ✅ Support URL
- ✅ Build upload
- ✅ Demo account information
- ✅ Export compliance
- ✅ Content rights

**📖 For detailed field-by-field instructions, see**: `APP_STORE_CONNECT_GUIDE.md`

---

## Phase 4: Build & Archive

### 4.1 Create Archive

```bash
# In Xcode:
# 1. Select "Any iOS Device" as destination
# 2. Product → Archive
# 3. Wait for archive to complete
```

### 4.2 Validate Archive

```bash
# In Archive Organizer:
# 1. Select the archive
# 2. "Validate App..."
# 3. Sign in with Apple ID
# 4. Fix any validation errors
```

### 4.3 Distribute to App Store

```bash
# In Archive Organizer:
# 1. Select the archive
# 2. "Distribute App"
# 3. Select "App Store Connect"
# 4. Select "Automatically manage signing"
# 5. Upload
```

---

## Phase 5: App Store Submission

### 5.1 Upload Screenshots

Required for all device sizes:
- **iPhone 6.7"**: 1290 x 2796 pixels
- **iPhone 6.5"**: 1242 x 2688 pixels
- **iPhone 5.5"**: 1242 x 2208 pixels

Minimum screenshots:
- 3 screenshots per device size
- Optional: iPad screenshots

### 5.2 App Preview Videos (Optional)

- 15-30 seconds
- Required device sizes
- Upload to App Store Connect

### 5.3 Submit for Review

1. Complete all required metadata
2. Add version release notes
3. Select content availability
4. **Add for Review** → **Submit for Review**

---

## Phase 6: TestFlight Beta Testing

### 6.1 Internal Testing

```bash
# Add internal testers:
# App Store Connect → Users and Roles → Testers
# Maximum: 100 internal testers
```

### 6.2 External Testing

```bash
# Create external test group:
# App Store Connect → TestFlight → External Test Groups
# Add testers via email or public link
# Requires review before external testing
```

---

## Build Configuration

### Release Build Settings

```swift
// In Xcode Build Settings:
- Configuration: Release
- Swift Optimization: -O
- Strip Debug Symbols: Yes
- Bitcode: Disabled (not required for iOS 18+)
- Minimum iOS Version: 16.0
```

---

## Verification Checklist

Before submission:

- [ ] All capabilities added
- [ ] API base URL configured
- [ ] Supabase credentials set
- [ ] Privacy policy URL added
- [ ] App screenshots prepared
- [ ] Age rating completed
- [ ] Privacy questionnaire answered
- [ ] Tested on physical device
- [ ] Crash reporting configured
- [ ] Analytics implemented
- [ ] Deep links working

---

## Common Rejection Reasons

1. **Missing metadata**: Complete all required fields
2. **Incomplete onboarding**: Ensure first-time UX works
3. **Crash on launch**: Test on multiple devices
4. **Privacy issues**: Complete privacy questionnaire honestly
5. **Web-like app**: Ensure native UI/UX
6. **Broken links**: Test all external links
7. **Missing permissions**: Add all usage descriptions

---

## Post-Launch Monitoring

### Analytics Integration

```swift
// Configure analytics in familyplusApp.swift
import FirebaseAnalytics
import Amplitude

// Initialize analytics
FirebaseApp.configure()
Amplitude.instance.initializeApiKey("YOUR_API_KEY")
```

### Crash Reporting

```bash
# Add Firebase Crashlytics via Swift Package Manager:
# https://firebase.google.com/docs/crashlytics
```

---

## Update Process

```bash
# For version updates:
# 1. Increment version in Xcode
# 2. Build new archive
# 3. Upload to App Store Connect
# 4. Add release notes
# 5. Submit for review
# 6. Wait for review (1-3 days)
```

---

## Emergency Hotfix

```bash
# If critical bug found:
# 1. Create expedited review request
# 2. Document issue and fix
# 3. Submit with "Expedited Review" option
# 4. Provide justification
# 5. Typical review time: 1-2 days
```

---

## Troubleshooting

### Archive fails
- Clean build folder: Cmd+Shift+K
- Clear derived data
- Check code signing certificates

### Upload fails
- Check network connection
- Verify Apple ID credentials
- Ensure App Store Connect app is created

### Rejection reasons
- Review rejection email carefully
- Fix issues in new build
- Resubmit with explanation

---

## Resources

- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
