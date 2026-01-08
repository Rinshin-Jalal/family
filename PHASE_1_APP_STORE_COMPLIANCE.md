# Phase 1: App Store Compliance Guide

**Goal**: Get StoryRide ready for App Store submission

**Estimated Time**: 2-3 hours (mostly design/manual work)

---

## 1. Missing Privacy Permissions (Info.plist)

**What**: iOS requires explicit permission descriptions in `Info.plist` for any sensitive data access.

**Why Required**: Apple's App Review **automatically rejects** apps that access sensitive features without these descriptions.

### Missing Permissions:

| Permission | Key | What It Does |
|------------|-----|--------------|
| **Camera** | `NSCameraUsageDescription` | Your app has camera functionality (`ImagePickerView.swift`) |
| **Photo Library** | `NSPhotoLibraryUsageDescription` | For selecting images from gallery |
| **Location** | `NSLocationWhenInUseUsageDescription` | Your `LocationPicker.swift` uses CoreLocation |
| **Notifications** | `NSUserNotificationUsageDescription` | Your `PushNotificationSettingsView.swift` requests notifications |

### File to Edit:
```
familyplus/familyplus/Info.plist
```

### Add These Keys:
```xml
<!-- Camera Permission -->
<key>NSCameraUsageDescription</key>
<string>StoryRide needs camera access to capture photos for your family stories</string>

<!-- Photo Library Permission -->
<key>NSPhotoLibraryUsageDescription</key>
<string>StoryRide needs photo library access to add images to your stories</string>

<!-- Location Permission -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>StoryRide uses location to tag where your family stories happen</string>

<!-- Notifications Permission -->
<key>NSUserNotificationUsageDescription</key>
<string>Get notified when family members add to your stories</string>
```

---

## 2. Fix iOS Deployment Target (iOS 26.2 → 16.0)

**What**: Change `IPHONEOS_DEPLOYMENT_TARGET` from `26.2` to `16.0`.

**Why This is Critical**:
- **iOS 26.2 doesn't exist** - this is clearly an error
- Current iOS is ~17.x, so 26.2 is impossible
- Targeting iOS 16.0+ covers 95%+ of active devices
- Prevents build/archiving issues

**File to Edit**:
```
familyplus/familyplus.xcodeproj/project.pbxproj
```

**Find and Replace**:
```
IPHONEOS_DEPLOYMENT_TARGET = 26.2;
↓
IPHONEOS_DEPLOYMENT_TARGET = 16.0;
```

---

## 3. App Icons & Signing

### App Icons
**What**: Create actual app icon assets (currently just a template)

**Required Sizes**:
- iPhone: 16x16, 20x20, 29x29, 40x40, 60x60, 64x64, 76x76, 83.5x83.5, 1024x1024
- iPad: 20x20, 29x29, 40x40, 76x76, 83.5x83.5, 1024x1024

**Where**: `familyplus/familyplus/Assets.xcassets/AppIcon.appiconset/`

**Action**: Design your app icon and add all required sizes

### Code Signing
**What**: Set up provisioning profiles & certificates

**Steps**:
1. Open Xcode → Select project → Signing & Capabilities
2. Enable "Automatically manage signing"
3. Select your Team (Apple Developer account required)
4. Xcode will generate provisioning profile automatically

**Note**: You'll need an Apple Developer Program account ($99/year)

---

## 4. App Store Connect Assets

### Screenshots (Required)
**What**: Screenshots for all supported device sizes

**Required Sizes**:
- iPhone 6.7" (1290x2796 pixels) - Pro Max
- iPhone 6.1" (1170x2532 pixels) - standard
- iPad Pro 12.9" (2048x2732 pixels)

**How to Create**:
1. Run app in Xcode simulator
2. Use Device → Capture Screenshots (or Cmd+S)
3. Use online tools to resize/crop to required dimensions

**Tips**:
- Show key features (story recording, family hub, etc.)
- No device frames in screenshots
- At least 3 screenshots per device

### Metadata (Required)
**What**: App store listing information

**Prepare**:
- **App Name**: StoryRide (or your choice)
- **Subtitle** (30 chars max): "Multi-generational family storytelling"
- **Description** (4000 chars max): Your app description
- **Keywords** (100 chars max): "family,stories,storytelling,memories,collaboration"
- **Category**: Social Networking or Lifestyle
- **Age Rating**: Calculate at Apple's guidelines (likely 4+)

### Privacy Policy URL (Required)
**What**: Link to your privacy policy

**If you collect data**: You MUST have a privacy policy
- Host on your website or use a free service
- Include: what data you collect, how you use it, contact info

---

## Risk Assessment

| Task | Risk if Not Done | Consequence |
|------|-----------------|-------------|
| Permissions | 🔴 **Critical** | **Instant rejection** |
| Deployment Target | 🔴 **Critical** | Build failure / rejection |
| App Icons | 🔴 **Critical** | **Cannot submit** |
| Signing | 🔴 **Critical** | **Cannot distribute** |
| Screenshots | 🔴 **Critical** | **Cannot submit** |
| Privacy Policy | 🟡 High | Rejection (delayed) |

---

## Implementation Checklist

### Code Changes (Claude can do):
- [ ] Add all 4 missing Info.plist permission keys
- [ ] Fix deployment target from 26.2 to 16.0

### Design Work (You need to do):
- [ ] Design app icon
- [ ] Create all app icon sizes
- [ ] Take screenshots from simulator
- [ ] Resize/crop screenshots to required dimensions
- [ ] Write app description
- [ ] Prepare keywords and category
- [ ] Create privacy policy (if needed)

### Apple Developer Setup:
- [ ] Enroll in Apple Developer Program ($99/year)
- [ ] Create App Store Connect app record
- [ ] Configure code signing in Xcode
- [ ] Generate provisioning profile

---

## Before Submitting

1. **Test on Real Device** (not just simulator)
2. **Test All Permission Flows** (camera, photos, location, notifications)
3. **Test Offline Behavior** (what happens without internet?)
4. **Run Performance Analysis** (Instruments in Xcode)
5. **Check for Crashes** (Xcode Organizer → Crashes)
6. **Verify Bundle ID** is unique (com.yourcompany.storyride)

---

## Quick Reference Commands

### Check Current Deployment Target:
```bash
grep -r "IPHONEOS_DEPLOYMENT_TARGET" familyplus/familyplus.xcodeproj/project.pbxproj
```

### Open Info.plist:
```bash
open familyplus/familyplus/Info.plist
```

### Open Project in Xcode:
```bash
open familyplus/familyplus.xcodeproj
```

---

## After Code Changes

Once Claude adds the permissions and fixes the target:

1. **Clean Build Folder**: Cmd+Shift+K in Xcode
2. **Build & Run**: Test on simulator to verify no errors
3. **Test Permissions**: Trigger each permission flow and verify the description shows
4. **Archive**: Product → Archive (to verify it works)
5. **Validate Archive**: Organizer → Validate App (checks for issues)

---

**Status**: Ready to implement when you are!
