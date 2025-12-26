# Backend Integration

This folder contains services for connecting the iOS app to Supabase and the Cloudflare Workers backend.

## Files

### AuthService.swift
Manages authentication state and JWT tokens.

**Methods:**
- `setToken(_:)` - Save auth token from Supabase
- `clearToken()` - Logout and clear token
- `getAuthHeader()` - Get Bearer token for API requests
- `isAuthenticated` - Published Bool for UI state

### SupabaseService.swift
Direct Supabase database client for authentication and queries.

**Methods:**
- `signInWithApple(idToken:nonce:)` - Sign in with Apple OAuth
- `signOut()` - Sign out from Supabase
- `getCurrentSession()` - Get current user session
- `getUserFamilyId()` - Get family ID for current user
- `getFamilyMembers(familyId:)` - Get all family members
- `getFamilyInviteSlug(familyId:)` - Get invite link slug
- `getFamilyStories(familyId:)` - Get all stories for family (with prompts & responses)
- `getStory(storyId:)` - Get single story with all responses

### APIService.swift
HTTP client for backend API endpoints.

**Stories:**
- `getStories()` - Fetch family stories
- `getStory(id:)` - Get single story with details
- `createStory(promptId:)` - Create new story
- `completeStory(id:title:summary:coverImageUrl:voiceCount:)` - Mark story complete with AI content

**Prompts:**
- `getPrompts()` - List family prompts
- `createPrompt(text:category:)` - Create custom prompt

**Responses (Audio Upload):**
- `uploadResponse(promptId:storyId:audioData:filename:source:)` - Upload audio file
- `transcribeResponse(responseId:)` - Trigger transcription

**Profiles:**
- `getFamilyMembers()` - Get all family members
- `addElder(name:phoneNumber:)` - Add elder (phone-only member)

**Reactions:**
- `addReaction(targetId:targetType:emoji:)` - Add emoji reaction

## Data Models

### FamilyMemberData
- `id: UUID`
- `authUserId: UUID?`
- `familyId: UUID`
- `fullName: String?`
- `avatarUrl: String?`
- `role: String` - 'organizer', 'elder', 'member', 'child'
- `phoneNumber: String?`
- `personaRole: PersonaRole` (computed)

### StoryData
- `id: UUID`
- `promptId: UUID?`
- `familyId: UUID`
- `title: String?`
- `summaryText: String?`
- `coverImageUrl: String?`
- `voiceCount: Int`
- `isCompleted: Bool`
- `createdAt: Date`
- `promptText: String?`
- `promptCategory: String?`
- `storytellerColor: Color` (computed from category)

### StoryDetailData
- `story: StoryData`
- `responses: [StorySegmentData]`

### StorySegmentData
- `id: UUID`
- `userId: UUID`
- `source: String` - 'phone_ai', 'app_audio', 'app_text'
- `mediaUrl: String?`
- `transcriptionText: String?`
- `durationSeconds: Int?`
- `createdAt: Date`
- `fullName: String` (from nested profile)
- `role: String`
- `avatarUrl: String?`
- `storytellerColor: Color` (computed from role)

### PromptData
- `id: String`
- `text: String`
- `category: String?`
- `isCustom: Bool`
- `createdAt: String`

### ResponseData
- `id: String`
- `promptId: String`
- `storyId: String?`
- `userId: String`
- `source: String`
- `mediaUrl: String?`
- `transcriptionText: String?`
- `durationSeconds: Int?`
- `processingStatus: String` - 'pending', 'completed', 'failed'
- `createdAt: String`

### ReactionData
- `id: String`
- `userId: String`
- `targetId: String`
- `targetType: String` - 'story' or 'response'
- `emoji: String`
- `createdAt: String`

## Usage Example

```swift
// 1. Sign in with Apple
let token = try await SupabaseService.shared.signInWithApple(idToken: idToken, nonce: nonce)
AuthService.shared.setToken(token)

// 2. Load family stories
let stories = try await SupabaseService.shared.getFamilyStories(familyId: familyId)

// 3. Or use API service
let apiStories = try await APIService.shared.getStories()
```

## TODO

- Replace Supabase URL and key with actual credentials
- Replace backend baseURL with deployed Cloudflare Workers URL
- Add Supabase SDK package to Xcode project
- Implement OpenAI integration in backend
- Implement Whisper transcription in backend
