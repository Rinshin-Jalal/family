# AGENTS.md

## Project Overview

**StoryRide** is a multi-generational, multiplayer family storytelling platform featuring a revolutionary adaptive UI system. The platform transforms its interface based on who is using it—four personas (Teen, Parent, Child, Elder)—each with completely different aesthetics, interactions, and accessibility needs.

**Tech Stack:**
- **Frontend**: iOS (SwiftUI) with adaptive theming system
- **Backend**: Cloudflare Workers (TypeScript + Hono)
- **Database**: Supabase (PostgreSQL with RLS)
- **Telephony**: Twilio integration for Elder phone-based interaction
- **AI**: OpenAI (Whisper for transcription, DALL-E for visuals)

---

## Commands

### Backend (TypeScript/Cloudflare Workers)

**Location**: `backend/`

```bash
# Install dependencies
npm install

# Development server (hot reload)
npm run dev
# or
npm start

# Deploy to Cloudflare
npm run deploy

# Build TypeScript (wrangler handles this)
npx tsc --noEmit
```

**Environment Setup**:
- `.dev.vars` contains local development variables
- Production secrets set via: `wrangler secret put <SECRET_NAME>`
- Required secrets: `SUPABASE_URL`, `SUPABASE_KEY`, `twilio_account_sid`, `twilio_auth_token`

### iOS App (Swift/Xcode)

**Location**: `familyplus/`

```bash
# Open in Xcode
open familyplus.xcodeproj

# Build from command line
xcodebuild -project familyplus.xcodeproj -scheme familyplus -destination 'platform=iOS Simulator,name=iPhone 15' build

# Run tests (if added)
xcodebuild test -project familyplus.xcodeproj -scheme familyplus -destination 'platform=iOS Simulator,name=iPhone 15'
```

**Build Configuration**:
- Project uses automatic code signing
- Bundle ID: `com.rinshinjalal.familyplus`
- iOS deployment target: 26.2
- SwiftUI Previews enabled (`ENABLE_PREVIEWS = YES`)

### Database (Supabase)

**Location**: `supabase/`

```bash
# Start local development stack
supabase start

# Stop local stack
supabase stop

# Reset database (destructive - be careful!)
supabase db reset

# Create a new migration
supabase migration new <migration_name>

# Apply migrations to remote
supabase db push

# Generate TypeScript types (not currently used, but recommended)
supabase gen types typescript --local
```

**Local Services Ports**:
- API: http://127.0.0.1:54321
- Database: 127.0.0.1:54322
- Studio: http://127.0.0.1:54323
- Inbucket (email testing): http://127.0.0.1:54324

---

## Code Organization

### Backend Structure (`backend/`)

```
backend/
├── src/
│   └── index.ts              # Main entry point with Hono app
├── .dev.vars                # Local environment variables
├── package.json             # Dependencies and scripts
├── tsconfig.json            # TypeScript config (strict mode)
└── wrangler.toml            # Cloudflare Workers config
```

**Key Patterns**:
- **Hono framework** for HTTP routing
- **R2 Bucket binding** for audio storage: `AUDIO_BUCKET`
- **Supabase client** factory pattern: `getSupabase(c)` per-request
- Type-safe environment bindings via Cloudflare Workers types

### iOS Structure (`familyplus/familyplus/`)

```
familyplus/
├── familyplusApp.swift         # @main app entry point
├── MainAppView.swift           # Root container
├── Theme/
│   ├── PersonaTheme.swift       # Core theming protocol & 4 theme implementations
│   ├── Color+Extensions.swift   # Design system color tokens
│   └── Font+Extensions.swift    # Design system typography
├── Components/
│   ├── AdaptiveButton.swift     # Buttons that adapt to persona
│   ├── StoryCard.swift         # Adaptive story cards (4 variants)
│   └── ProfileSwitcher.swift   # Netflix-style profile switcher
├── Screens/
│   ├── HubView.swift           # Home feed (4 layouts: scroll/grid/single/minimal)
│   ├── StudioView.swift        # Creation/recording page
│   ├── ProfileView.swift       # User profile/stats
│   └── StoryDetailView.swift  # Story playback with timeline
└── Assets.xcassets/          # Images, colors, app icons
```

**Architecture Pattern**:
- **Protocol-based theming**: All 4 personas conform to `PersonaTheme` protocol
- **Environment propagation**: Theme passed via `@Environment(\.theme)` throughout view tree
- **Adaptive components**: Views read `theme.role` and switch layouts automatically
- **Preview-friendly**: All views have Xcode previews with all 4 themes

### Database Structure (`supabase/`)

```
supabase/
├── migrations/
│   └── 20231220000000_initial_schema.sql   # Complete database schema
├── seed.sql                               # Sample data
├── config.toml                            # Supabase CLI configuration
└── .gitignore
```

**Schema Overview**:
- **Row Level Security (RLS)** enabled on all tables
- Users can ONLY access their family's data via subquery pattern
- **Shadow profiles** for Elders (no auth_user_id)
- **Trigger** `handle_new_user()` auto-creates family/profile on sign-up
- **Invite system** via unique `invite_slug` (8-char hex)

---

## Coding Patterns & Conventions

### Backend (TypeScript)

**Hono Route Pattern**:
```typescript
import { Hono } from 'hono'

type Bindings = {
  SUPABASE_URL: string
  SUPABASE_KEY: string
  AUDIO_BUCKET: R2Bucket
}

const app = new Hono<{ Bindings: Bindings }>()

app.get('/', (c) => c.text('Hello World'))

export default { fetch: app.fetch }
```

**TypeScript Config**:
- `strict: true` enabled
- Target: ESNext with WebWorker types
- Isolated modules for Cloudflare Workers

### iOS (SwiftUI)

**Theme-Aware View Pattern**:
```swift
struct MyView: View {
    @Environment(\.theme) var theme  // Access current theme

    var body: some View {
        Text("Hello")
            .font(theme.headlineFont)
            .foregroundColor(theme.textColor)
            .background(theme.backgroundColor)
    }
}
```

**Adaptive Component Pattern**:
```swift
struct AdaptiveCard: View {
    let data: Story
    @Environment(\.theme) var theme

    var body: some View {
        switch theme.role {
        case .teen:
            TeenCard(data: data)
        case .parent:
            ParentCard(data: data)
        case .child:
            ChildCard(data: data)
        case .elder:
            ElderCard(data: data)
        }
    }
}
```

**Protocol-Based Theme System**:
```swift
protocol PersonaTheme {
    var role: PersonaRole { get }
    var backgroundColor: Color { get }
    var textColor: Color { get }
    var accentColor: Color { get }
    var headlineFont: Font { get }
    var bodyFont: Font { get }
    var screenPadding: CGFloat { get }
    var cardRadius: CGFloat { get }
    var buttonHeight: CGFloat { get }
    var animation: Animation { get }
    var showNavigation: Bool { get }
    var enableAudioPrompts: Bool { get }
    var enableHaptics: Bool { get }
}
```

**Color Usage** (from `Color+Extensions.swift`):
```swift
// Base colors
Color.inkBlack        // Teen background (#000000)
Color.paperWhite      // Parent/Child background (#FFFFFF)
Color.warmYellow      // Elder background (#FFF9C4)
Color.surfaceGrey     // Light cards (#F2F2F7)
Color.darkGrey        // Dark cards (#1C1C1E)

// Accents
Color.brandIndigo     // Primary (#5856D6)
Color.alertRed        // Stop/delete (#FF3B30)
Color.playfulOrange   // Child accent (#FF9500)

// Storyteller colors (timeline)
Color.storytellerOrange  // Elder segments
Color.storytellerBlue    // Parent segments
Color.storytellerPurple  // Teen segments
Color.storytellerGreen   // Child segments
```

**Haptic Feedback Pattern**:
```swift
Button(action: {
    if theme.enableHaptics {
        let impact = UIImpactFeedbackGenerator(
            style: theme.role == .child ? .heavy : .light
        )
        impact.impactOccurred()
    }
    action()
}) { /* UI */ }
```

### Database (PostgreSQL)

**RLS Pattern** (users see only their family's data):
```sql
CREATE POLICY "Users can view family stories" ON stories
    FOR SELECT USING (
        family_id IN (SELECT family_id FROM profiles WHERE auth_user_id = auth.uid())
    );
```

**Trigger Pattern** (auto-handle sign-up logic):
```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    v_invite_slug TEXT;
    v_family_id UUID;
BEGIN
    v_invite_slug := new.raw_user_meta_data->>'invite_slug';

    IF v_invite_slug IS NOT NULL THEN
        -- Join existing family
        SELECT id INTO v_family_id FROM families WHERE invite_slug = v_invite_slug;
    ELSE
        -- Create new family + invite slug
        v_invite_slug := lower(substring(encode(gen_random_bytes(16), 'hex'), 1, 8));
        INSERT INTO public.families (name, invite_slug) VALUES (...);
    END IF;

    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## Naming Conventions

### Swift/iOS

- **Views**: PascalCase (e.g., `HubView`, `TeenHub`, `ParentHub`)
- **Components**: PascalCase (e.g., `AdaptiveButton`, `StoryCard`)
- **Themes**: `[Persona]Theme` (e.g., `DarkTheme`, `LightTheme`)
- **Properties**: camelCase (e.g., `screenPadding`, `buttonHeight`)
- **Color extensions**: `Color.name` (e.g., `Color.inkBlack`, `Color.brandIndigo`)
- **File organization**: Group by feature (Theme/, Components/, Screens/)

### TypeScript/Backend

- **Route handlers**: Lowercase verb (e.g., `app.get()`, `app.post()`)
- **Type definitions**: PascalCase (e.g., `Bindings`)
- **Variables**: camelCase (e.g., `SUPABASE_URL`, `AUDIO_BUCKET`)

### Database

- **Tables**: snake_case singular (e.g., `profiles`, `stories`, `responses`)
- **Columns**: snake_case (e.g., `auth_user_id`, `family_id`, `invite_slug`)
- **Enums**: snake_case (e.g., `user_role`, `response_source`)
- **Functions**: snake_case (e.g., `handle_new_user`, `add_elder_to_family`)
- **Policies**: Descriptive string (e.g., `"Users can view own family"`)
- **Indexes**: `idx_table_column` pattern (e.g., `idx_profiles_auth_user`)

---

## The 4 Personas (Critical Context)

### Teen (16-22)
**Aesthetic**: Dark mode, minimalist, Instagram-style
- Background: `#000000` (Ink Black)
- Accent: `#5856D6` (Brand Indigo)
- Font: SF Pro Display Bold + New York Serif
- Layout: Full-screen cards, vertical scroll
- Navigation: Minimalist dock, hidden when possible
- Touch targets: 44x44pt
- Animation: Snappy spring (0.3s)
- Input: Voice + Text

### Parent (25-45)
**Aesthetic**: Light mode, organized, dashboard
- Background: `#FFFFFF` (Paper White)
- Accent: `#5856D6` (Brand Indigo)
- Font: SF Pro Semibold
- Layout: Masonry grid (Pinterest-style)
- Navigation: Standard iOS Tab Bar
- Touch targets: 48x48pt
- Animation: Smooth ease-in-out (0.3s)
- Input: Voice + Text + Edit

### Child (3-12)
**Aesthetic**: Bright, tactile, audio-first
- Background: `#FFFFFF` (Paper White)
- Accent: `#FF9500` (Playful Orange)
- Font: SF Pro Rounded Heavy (32pt headlines)
- Layout: Single giant card, no scroll
- Navigation: Hidden (linear flow with arrows)
- Touch targets: 80x80pt (huge)
- Animation: Bouncy spring (0.4s)
- Input: Voice only
- Features: Confetti, stickers, TTS prompts

### Elder (70+)
**Aesthetic**: High contrast, large text, phone-based
- Background: `#FFF9C4` (Warm Yellow)
- Accent: `#5856D6` (Brand Indigo)
- Font: SF Pro Bold (34pt headlines, 28pt body)
- Layout: Single centered card
- Navigation: Hidden (one screen at a time)
- Touch targets: 60x60pt
- Animation: Slow fade (0.5s)
- Input: Phone AI only (no app interaction)
- Features: Maximum legibility, auto-read TTS

---

## Important Gotchas

### Backend

1. **Supabase Client per Request**: Don't create a single client—use `getSupabase(c)` for each request to get correct environment bindings
2. **R2 Bucket Access**: `c.env.AUDIO_BUCKET` only works in Cloudflare Workers environment
3. **Secrets Management**: `.dev.vars` is for local dev only—never commit. Use `wrangler secret put` for production.
4. **Node.js Compatibility**: `nodejs_compat` flag in `wrangler.toml` enables Node.js APIs in Workers

### iOS

1. **Theme Propagation**: Always use `@Environment(\.theme)`—never hardcode colors/fonts
2. **Preview Testing**: Preview ALL views with all 4 themes before committing
3. **Accessibility**: Every interactive element needs `.accessibilityLabel()` and `.accessibilityHint()`
4. **Child Mode Constraints**: Remember child has NO navigation bar—use arrows only
5. **Elder Mode**: Elder has NO app interaction (phone-based), UI is minimal
6. **Color System**: Use design system colors (e.g., `Color.brandIndigo`) not hex literals
7. **Haptic Respect**: Always check `theme.enableHaptics` before triggering

### Database

1. **RLS is Mandatory**: Every table has RLS—access always filtered by family_id
2. **Shadow Profiles**: Elders have `auth_user_id = NULL`—never require auth.users join
3. **Invite Slug Generation**: Uses random 8-char hex—ensure unique constraint
4. **Migration Order**: Always number migrations chronologically (YYYYMMDDHHMMSS)
5. **Trigger Timing**: `handle_new_user()` runs AFTER INSERT on `auth.users`
6. **Subquery Performance**: RLS policies use subqueries—index `profiles(family_id)` is critical

### General

1. **No Test Framework**: Project currently has no tests—manual testing required
2. **Supabase Local**: Database must be running locally (`supabase start`) for backend dev
3. **Xcode Version**: Project created with Xcode 26.2—use compatible version
4. **Code Signing**: Automatic code signing configured—no manual cert management needed

---

## Testing Approach

### Currently: Manual Testing Only

**iOS**:
- Use Xcode Previews to verify all 4 themes
- Test in Simulator for different device sizes
- Verify VoiceOver accessibility labels
- Test profile switching (instant theme changes)

**Backend**:
- Run `npm run dev` with `supabase start`
- Test endpoints via Postman/curl
- Verify RLS policies with multiple test users
- Test R2 bucket upload/download

**Database**:
- Test migrations locally: `supabase db reset`
- Verify RLS with `supabase db diff` before `db push`
- Test `handle_new_user()` trigger with invite link flow

### Recommended Tests (Not Yet Implemented)

- **SwiftUI**: Snapshot tests for theme variations
- **Backend**: Unit tests for route handlers, integration tests for R2/Supabase
- **Database**: Migration rollback tests, RLS policy coverage

---

## Deployment

### Backend to Cloudflare Workers

```bash
npm run deploy
```

This deploys to Cloudflare's global edge network. Secrets must be set first:
```bash
wrangler secret put SUPABASE_URL
wrangler secret put SUPABASE_KEY
wrangler secret put twilio_account_sid
wrangler secret put twilio_auth_token
```

### Database to Supabase Cloud

```bash
# Review changes first
supabase db diff

# Apply migrations
supabase db push
```

**Important**: Always run `supabase db diff` locally before pushing to remote.

### iOS to App Store

1. Build for Archive in Xcode
2. Upload via Xcode Organizer
3. Configure App Store Connect metadata
4. Submit for review

---

## Documentation Files

- `PRD.md` - Full Product Requirements Document
- `IMPLEMENTATION_GUIDE.md` - Detailed Adaptive UI implementation guide
- `ADAPTIVEUI.md` - Adaptive UI system overview
- `DESIGNSYSTEM.md` - Design system tokens and usage
- `plan.md` - Project planning notes
- `PAGES.md` - Site structure reference

---

## File-Scoped Knowledge

### `backend/src/index.ts`
- Only 22 lines—minimal Hono setup
- Missing: All route handlers, authentication middleware, error handling

### `familyplus/familyplus/Theme/PersonaTheme.swift`
- **Core file**—defines the 4 theme implementations
- Contains `ThemeFactory` for theme lookup
- Defines Environment Key for theme propagation
- 249 lines—comprehensive theme system

### `familyplus/familyplus/Screens/HubView.swift`
- Demonstrates adaptive layouts: Teen (scroll), Parent (grid), Child (single), Elder (minimal)
- Shows how to switch layouts based on `theme.role`
- Contains sample data in extension

### `supabase/migrations/20231220000000_initial_schema.sql`
- Complete schema with RLS policies
- 311 lines—comprehensive
- Includes functions, triggers, indexes, views
- **Do not modify**—create new migration instead

---

## Common Workflows

### Adding a New Adaptive Component

1. Create component file in `Components/`
2. Read `@Environment(\.theme)` in body
3. Switch on `theme.role` to return persona-specific view
4. Create separate structs for each variant if complex
5. Add preview with all 4 themes
6. Test profile switching

### Adding a New Backend Route

1. Import dependencies in `src/index.ts`
2. Add route: `app.get('/endpoint', handler)`
3. Access env via `c.env.SUPABASE_URL`, etc.
4. Create Supabase client: `const supabase = getSupabase(c)`
5. Return JSON: `return c.json(data, 200)`
6. Test with `wrangler dev`

### Adding a Database Table

1. Create migration: `supabase migration new add_feature_table`
2. Write `CREATE TABLE` with proper foreign keys
3. Add RLS policies (copy pattern from existing tables)
4. Add indexes for performance
5. Run locally: `supabase db reset`
6. Verify in Studio: http://127.0.0.1:54323
7. Push to remote: `supabase db push`

---

## Security Considerations

1. **RLS is Critical**: All database access must go through Supabase auth + RLS
2. **No Secrets in Code**: All secrets in `.dev.vars` (gitignored) or Cloudflare secrets
3. **Elder Privacy**: Elders' phone numbers stored in profiles table—restrict access
4. **Invite Links**: 8-char hex slugs are guessable—consider rate limiting
5. **Audio Files**: Store in R2 with private access—generate signed URLs
6. **Input Validation**: Validate all user input before database insertion
7. **SQL Injection**: Use parameterized queries (Supabase client handles this)

---

## Performance Notes

1. **Database Indexes**: All foreign keys and frequently queried columns are indexed
2. **RLS Overhead**: Subqueries in RLS policies can be slow—optimize with joins
3. **SwiftUI Re-renders**: Use `@Environment` for theme to minimize re-renders
4. **Image Loading**: Use `AsyncImage` with placeholder for story cards
5. **Lazy Loading**: Use `LazyVStack` / `LazyVGrid` for large lists
6. **Audio Storage**: R2 is fast but not instantaneous—show loading states
7. **Cloudflare Workers**: Cold starts ~50ms—warm < 5ms

---

## External Integrations

### Supabase
- **Auth**: Sign in with Apple configured
- **Database**: PostgreSQL 17 with RLS
- **Storage**: Not currently used for audio (R2 instead)
- **Realtime**: Enabled but not used yet
- **Edge Functions**: Not used (using Cloudflare Workers instead)

### Twilio
- **Phone AI**: Elders receive AI calls (planned, not implemented)
- **Account SID**: Must be set via `wrangler secret put twilio_account_sid`
- **Auth Token**: Must be set via `wrangler secret put twilio_auth_token`

### OpenAI
- **Whisper**: Audio transcription (planned, not implemented)
- **DALL-E**: Story cover image generation (planned, not implemented)
- **GPT-4**: Story synthesis from multiple responses (planned, not implemented)

---

## Development Workflow

1. **Start Services**: Run `supabase start` in one terminal, `npm run dev` in backend directory in another
2. **Open Xcode**: Open `familyplus.xcodeproj` to work on iOS
3. **Backend Changes**: Edit `backend/src/index.ts`, test at http://localhost:8787 (wrangler default)
4. **iOS Changes**: Edit SwiftUI files, use Live Previews for instant feedback
5. **Database Changes**: Create migration, test locally, verify in Studio
6. **Theme Testing**: Always test with Profile Switcher to verify all 4 personas
7. **Stop Services**: `supabase stop` when done, `Ctrl+C` to stop wrangler

---

## Troubleshooting

### Backend Issues

- **Port 8787 in use**: Wrangler uses this by default—kill process or change port in `wrangler.toml`
- **Supabase connection failed**: Ensure `supabase start` is running and `.dev.vars` URL matches
- **Type errors**: Run `npx tsc --noEmit` to check without building

### iOS Issues

- **Previews not updating**: Clean build folder (Cmd+Shift+K) and restart Xcode
- **Theme not applying**: Ensure `.themed()` modifier is applied at root of view tree
- **Color not changing**: Check you're using `theme.colorName` not literal values
- **Build fails**: Verify Xcode version (26.2+), clean derived data

### Database Issues

- **Migration failed**: Check SQL syntax in migration file
- **RLS blocking access**: Verify user is logged in via Supabase Studio
- **Seed data not loading**: Ensure `supabase/db.seed.enabled = true` in `config.toml`
- **Studio not accessible**: Run `supabase status` to check services

---

## Key Files for New Agents

If you're new to this codebase, read in this order:

1. **`familyplus/familyplus/Theme/PersonaTheme.swift`** - Understand the adaptive theming system
2. **`familyplus/IMPLEMENTATION_GUIDE.md`** - Complete architecture overview
3. **`supabase/migrations/20231220000000_initial_schema.sql`** - Database schema and RLS
4. **`backend/src/index.ts`** - Backend entry point (currently minimal)
5. **`PRD.md`** - Product requirements and user flows
6. **`familyplus/familyplus/Screens/HubView.swift`** - Example of adaptive layouts in action

---

**Last Updated**: 2025-12-24
