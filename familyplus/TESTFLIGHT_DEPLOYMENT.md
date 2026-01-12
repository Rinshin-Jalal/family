# TestFlight Launch Guide - Family+

**Goal**: Get app to testers fast, iterate quickly, gather feedback before App Store launch.

**Why TestFlight First?**
- ⚡ Faster to launch (hours vs days)
- 🔒 Safe testing environment (up to 10,000 testers)
- 🐛 Quick bug fixes and updates
- 📊 Real user feedback before public launch
- ✅ No strict review requirements initially

---

## 🚀 TestFlight vs App Store Launch

| Aspect | TestFlight | App Store |
|--------|------------|-----------|
| **Review Time** | 1-2 days (internal: none) | 1-3 days |
| **Screenshots** | Optional | Required (3-10 per device) |
| **Metadata** | Minimal required | Complete everything |
| **Privacy** | Basic disclosure | Full detailed questionnaire |
| **Testers** | Up to 10,000 | Unlimited |
| **Updates** | Multiple per day | Limited by review |
| **Public** | Private testers | Anyone |
| **Expiration** | 90 days per build | Never |

---

## 🎯 Phase 1: Internal Testing (No Review Required)

**Time to Launch**: ~1 hour
**Max Testers**: 100 (your team/friends)
**Review Required**: ❌ None

### Step 1: Create App in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. **My Apps** → **+** → **New App**
3. Fill in:
   - **Platform**: iOS
   - **Name**: Family+
   - **Bundle ID**: `com.yourcompany.familyplus`
   - **SKU**: `FAMILYPLUS001`

### Step 2: Minimal App Information

**Only these fields required for internal testing**:

| Field | Value | Notes |
|-------|-------|-------|
| **Name** | Family+ | Public name |
| **Bundle ID** | com.yourcompany.familyplus | Match Xcode |
| **SKU** | FAMILYPLUS001 | Internal ID |

**Skip for now** (not required for internal testing):
- ❌ Screenshots (optional)
- ❌ Description (can be brief)
- ❌ Keywords
- ❌ Promotional text
- ❌ Privacy policy URL (recommended but not enforced)
- ❌ Age rating questionnaire

### Step 3: Build & Upload

```bash
# Open in Xcode
open familyplus.xcodeproj

# In Xcode:
1. Select scheme: familyplus
2. Select destination: Any iOS Device
3. Product → Archive
4. Wait for archive to complete
5. Window → Organizer
6. Select your archive
7. Distribute App → App Store Connect
8. Upload
```

**Build Settings for TestFlight**:
```bash
# In Xcode Build Settings:
- Configuration: Release
- Version: 0.1.0 (use < 1.0 for beta)
- Build: 1
- Team: Your development team
```

### Step 4: Add Internal Testers

**Navigation**: App Store Connect → Your App → TestFlight → Internal Testing

1. Click **+** to add testers
2. Add team members:
   - They must be added to your team in [App Store Connect → Users and Roles](https://appstoreconnect.apple.com/users/roles)
   - Maximum 100 internal testers

3. **Or** invite by email:
   - Enter email addresses
   - They'll receive TestFlight invite

### Step 5: Distribute to Internal Testers

1. Select your build in TestFlight
2. Click **Add for Testing**
3. Select **Internal Testing**
4. Add testers (or select "All Internal Testers")
5. Click **Start Test**

**No review required!** Testers can download immediately via TestFlight app.

### Step 6: Tester Instructions

Send this to your testers:

```
📱 Family+ Beta Test - TestFlight Setup

1. Download TestFlight from App Store (if not installed)
2. Open the invite email from Apple
3. Click "View in TestFlight"
4. Install Family+ beta app
5. Launch and test!

Testing Focus:
- ✅ Can you sign up with Apple?
- ✅ Can you record audio story?
- ✅ Can you upload photo?
- ✅ Can you play back audio?
- ✅ Any crashes or bugs?

Feedback: Reply to this email with issues
Thanks for testing! 🙏
```

---

## 🎯 Phase 2: External Testing (Light Review Required)

**Time to Launch**: 1-2 days for review
**Max Testers**: 10,000
**Review Required**: ✅ Yes (but simplified)

### When to Move to External Testing?

- ✅ Internal testing completed
- ✅ Critical bugs fixed
- ✅ Core features working
- ✅ Ready for broader feedback

### Step 1: Complete Required Metadata

**Minimal requirements for external testing**:

| Field | Value | Required for External |
|-------|-------|----------------------|
| **Name** | Family+ | ✅ Yes |
| **Category** | Social Networking | ✅ Yes |
| **Age Rating** | 4+ (complete questionnaire) | ✅ Yes |
| **Privacy URL** | https://yourdomain.com/privacy | ✅ Yes |
| **Description** | Brief app description | ✅ Yes |
| **Screenshots** | At least 1 per device | ⚠️ Recommended |

### Step 2: Complete Age Rating

**Navigate**: App Store Connect → Your App → Age Rating

**For Family+ (answer all No)**:
- Graphic sexual content: No
- Profanity: No
- Violence: No
- etc.

**Result**: 4+ rating

### Step 3: Add Privacy Policy URL

**Quick Options**:

**Option 1: Host a simple page**
```html
<!-- https://yourdomain.com/privacy -->
<!DOCTYPE html>
<html>
<head><title>Family+ Privacy Policy</title></head>
<body>
<h1>Family+ Privacy Policy</h1>
<p>Last Updated: January 2026</p>

<h2>What We Collect</h2>
<ul>
  <li>Email address (for account creation)</li>
  <li>Audio recordings (your family stories)</li>
  <li>Photos (your family memories)</li>
  <li>App usage data (to improve the app)</li>
</ul>

<h2>How We Use It</h2>
<ul>
  <li>Provide and maintain the app</li>
  <li>Process your stories and memories</li>
  <li>Send you app updates</li>
  <li>Analyze usage to improve features</li>
</ul>

<h2>Data Sharing</h2>
<p>We do not sell your data. We only share data with:</p>
<ul>
  <li>Cloudflare (app hosting)</li>
  <li>Supabase (database)</li>
  <li>AI services (transcription, text processing)</li>
</ul>

<h2>Your Rights</h2>
<ul>
  <li>Access your data</li>
  <li>Delete your account and data</li>
  <li>Export your data</li>
  <li>Opt out of communications</li>
</ul>

<h2>Contact</h2>
<p>Questions: support@yourdomain.com</p>
</body>
</html>
```

**Option 2: Use a free privacy policy generator**
- https://www.privacypolicygenerator.info/
- https://www.freeprivacypolicy.com/
- Customize for your app

### Step 4: Add Basic Description

```
Family+ - Private family storytelling app.

Capture your family's stories, wisdom, and voice across generations.

Features:
• Record audio stories with AI-generated prompts
• Upload photos with family memories
• Extract wisdom from family conversations
• Private family-only sharing
• Replay anytime, anywhere

Beta testing - we'd love your feedback!

Privacy: yourdomain.com/privacy
Support: yourdomain.com/support
```

### Step 5: Add Screenshots (Minimum)

**For TestFlight, you only need 1 screenshot per device size** (vs 3-10 for App Store)

| Device | Size | Min Screenshots |
|--------|------|-----------------|
| iPhone 6.7" | 1290 x 2796 | 1 |
| iPhone 6.5" | 1242 x 2688 | 1 |
| iPhone 5.5" | 1242 x 2208 | 1 |

**Quick screenshot approach**:
1. Run app in simulator
2. Take screenshot (Cmd+S)
3. Use 1 key screen per device type
4. Upload to TestFlight

### Step 6: Create External Test Group

**Navigation**: App Store Connect → Your App → TestFlight → External Testing

1. Click **+** Create new group
2. Group name: "Beta Testers v1.0"
3. Add build (same as internal)
4. **App Information** → Fill out basic info:
   - What to test
   - Test instructions
   - Feedback email

**Test Information Template**:
```
What to Test:
• Sign up with Apple
• Record audio story (tap + → Voice)
• Upload photo (tap + → Photo)
• Play back stories
• Invite family members
• Settings and profile

Known Issues:
• None currently

Testing Focus:
• Audio recording quality
• Photo upload success
• Playback smoothness
• Crash detection

Feedback: bugs@yourdomain.com
Thank you for testing!
```

### Step 7: Submit for Review

1. Click **Submit for Review**
2. Review type: **External Testing**
3. Answer questions:
   - **Demo account required**: Yes
   - **Demo instructions**: See below

4. Submit

**Demo Account Instructions**:
```
Demo Account for Testing:

This app uses Sign in with Apple only.
No password required.

To test:
1. Tap "Sign up with Apple"
2. Complete onboarding
3. Create family or join existing
4. Test core features

Test data is isolated per family.
All features fully functional.
```

### Step 8: Wait for Review (1-2 days)

You'll get email when approved. Then:

1. Go to TestFlight → External Testing
2. Click **Start Test**
3. Share public link: `https://testflight.apple.com/join/YOUR_CODE`

**Invite Testers**:
```
🎉 You're invited to test Family+!

Join our beta program:
https://testflight.apple.com/join/YOUR_CODE

What's Family+?
A private app for capturing family stories,
wisdom, and memories across generations.

We need your help testing:
• Audio recording quality
• Photo uploads
• Story playback
• Overall experience

Download TestFlight and install the beta.

Questions? Reply to this email!

Thanks for being an early tester! 🙏
```

---

## 🔄 Rapid Iteration with TestFlight

### Update Cycle (Hours vs Days)

```bash
# Found a bug? Fix and redeploy same day!

1. Fix bug in Xcode
2. Increment build number (1 → 2)
3. Product → Archive
4. Upload to TestFlight
5. Add to testing (replace previous build)
6. Testers get notification instantly

# No review needed for internal testing!
# External testing: simplified review (<24 hours for updates)
```

### Version Strategy

| Version | Type | Purpose |
|---------|------|---------|
| 0.1.0 (Build 1) | Internal | Team testing, crash bugs |
| 0.1.1 (Build 2) | Internal | Bug fixes |
| 0.2.0 (Build 3) | External | First beta testers |
| 0.2.1 (Build 4) | External | Feedback fixes |
| 0.3.0 (Build 5) | External | New features |
| 1.0.0 (Build X) | App Store | Public launch |

---

## 📊 TestFlight Analytics

### Monitor in App Store Connect

**Navigation**: App Store Connect → Your App → TestFlight → Analytics

**Metrics to Track**:
- **Crashes**: Free crashes in TestFlight = angry users
- **Sessions**: How many testers use it
- **Active Devices**: Daily/weekly active testers
- **Installs**: Successful installations

### Tester Feedback

**In-App Feedback** (implement in code):
```swift
// Add feedback button in settings
Button(action: {
    // Open TestFlight review
    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
        SKStoreReviewController.requestReview(in: scene.window!)
    }
}) {
    Label("Send Feedback", systemImage: "envelope")
}
```

**Or collect via email**:
```
Feedback link: mailto:beta@yourdomain.com?subject=Family+ Beta Feedback
```

---

## 🎯 TestFlight Testing Checklist

### Week 1: Internal Testing (Team)

- [ ] App installs without crash
- [ ] Sign up with Apple works
- [ ] Can record audio story
- [ ] Can upload photo
- [ ] Can play back audio
- [ ] Can view story details
- [ ] Can invite family member
- [ ] Settings work
- [ ] Background audio works
- [ ] No memory leaks
- [ ] No obvious bugs

### Week 2-3: External Testing (Beta Users)

- [ ] Onboarding flow smooth
- [ ] Audio quality good
- [ ] Photo uploads succeed
- [ ] Playback works on all devices
- [ ] Family invites work
- [ ] Deep links work
- [ ] Push notifications (if enabled)
- [ ] Offline mode graceful
- [ ] Performance acceptable
- [ ] Collect 10+ feedback reports

### Week 4: Polish

- [ ] Fix all critical bugs
- [ ] Improve UX from feedback
- [ ] Add missing features
- [ ] Optimize performance
- [ ] Prepare for App Store

---

## 🚀 From TestFlight to App Store

### When Ready for Public Launch

1. **Complete all App Store metadata** (see `APP_STORE_CONNECT_GUIDE.md`)
2. **Prepare full screenshot set** (3-10 per device)
3. **Write polished description**
4. **Complete full privacy questionnaire**
5. **Create app preview video** (optional but recommended)
6. **Submit for App Store review**
7. **Wait 1-3 days**

**Or**: Keep in TestFlight for private beta (some apps never launch publicly!)

---

## 🎓 TestFlight Best Practices

### DO ✅

- ✅ Start with internal testing (your team)
- ✅ Fix obvious bugs before external testing
- ✅ Use descriptive build notes
- ✅ Respond to tester feedback
- ✅ Update frequently (shows activity)
- ✅ Test on real devices (not just simulator)
- ✅ Test on older iOS versions
- ✅ Test on iPad (if supporting)

### DON'T ❌

- ❌ Ship to external testers with known crashes
- ❌ Ignore tester feedback
- ❌ Use testers as QA (test first!)
- ❌ Leave builds expired (90 days max)
- ❌ Skip basic testing before upload
- ❌ Forget to increment build numbers
- ❌ Release all features at once

---

## 📱 Tester Communication Templates

### Beta Invite Email

```
Subject: You're invited to test Family+! 🎉

Hey [Name],

I'm building a new app called Family+ - it's a private app
for capturing family stories, wisdom, and memories.

I'd love your help testing it!

**What to expect:**
⏱️ 5-10 minutes of testing per week
🐛 You might find bugs (that's okay!)
💬 Your feedback shapes the app

**How to join:**
1. Install TestFlight from App Store
2. Tap this link on your iPhone: [TESTFLIGHT LINK]
3. Install the Family+ beta

**What to test:**
• Record a voice story
• Upload a family photo
• Play back memories
• Tell me what you think!

**Feedback:**
Reply to this email with thoughts, bugs, or ideas.

Thanks for being an early tester! 🙏

[Your Name]
```

### Weekly Update Email

```
Subject: Family+ Beta - New Features! ✨

Hey testers!

**What's New (v0.2.0):**
✨ Feature: Photo sharing
🐛 Bug fix: Audio playback now works on iPhone 8
💅 UI: Cleaner story cards

**Testing Focus This Week:**
• Try uploading photos from your camera roll
• Test audio quality on different devices
• Invite a family member to your family

**Known Issues:**
• Sometimes takes 10s to upload (fixing in v0.2.1)
• iPad layout needs work (next week)

**Your Feedback:**
Last week 5 testers reported [BUG]. Fixed in this version!
Keep the feedback coming!

Update in TestFlight → Install new version
Reply with thoughts! 💬

[Your Name]
```

---

## 🔗 Useful Links

- [TestFlight Documentation](https://developer.apple.com/testflight/)
- [App Store Connect](https://appstoreconnect.apple.com)
- [TestFlight Help](https://help.apple.com/app-store-connect/#/devdc42b23b6)

---

## ✅ Launch Checklist

### Internal Testing (Team)
- [ ] App created in App Store Connect
- [ ] Build uploaded
- [ ] Internal testers added (max 100)
- [ ] Testers can install via TestFlight
- [ ] Core features tested
- [ ] Critical bugs fixed

### External Testing (Beta)
- [ ] Age rating completed
- [ ] Privacy policy URL set
- [ ] Basic description added
- [ ] Screenshots uploaded (1 per device)
- [ ] External test group created
- [ ] Submitted for review
- [ ] Review approved (1-2 days)
- [ ] Public link shared
- [ ] Testers invited
- [ ] Feedback collection set up

### Ready for App Store
- [ ] All features working
- [ ] No critical bugs
- [ ] 10+ positive feedback reports
- [ ] Performance optimized
- [ ] All metadata complete
- [ ] Full screenshot set ready
- [ ] App preview video (optional)

---

**Last Updated**: 2026-01-12
**Status**: 🟢 Ready for TestFlight
**Next**: Submit to internal testing!
