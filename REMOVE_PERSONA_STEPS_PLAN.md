🔄 Refactoring Plan: Persona → Dark/Light Theme
Summary
Transform the current 4-persona adaptive UI system (Teen, Parent, Child, Elder) into a simple 2-theme system (Dark Mode, Light Mode). Remove all Child and Elder specific screens, layouts, and navigation patterns. Teen becomes Dark Mode, Parent becomes Light Mode.
---
High-Level Changes
1. Theme System Refactoring
Before:
PersonaRole: { teen, parent, child, elder }
Themes: { DarkTheme, LightTheme, LightTheme, LightTheme }
After:
AppTheme: { dark, light }
Themes: { DarkTheme, LightTheme }
2. Navigation Simplification
Before:
TeenNavigation  (Floating bar)
ParentNavigation (Standard tab bar)
ChildNavigation (No nav, linear flow)
ElderNavigation  (Single screen)
After:
Standard TabView (Same for both themes, just theming changes)
3. Profile System Simplification
Before:
4 persona profiles: Leo (teen), Mom (parent), Mia (child), Grandma (elder)
After:
Simple theme toggle (sun/moon icon) in settings or top-right
---
Detailed File Changes
🎨 Core Theme Files
1. familyplus/familyplus/Theme/PersonaTheme.swift → Theme.swift
Changes:
- Rename PersonaRole enum to AppTheme with cases: .dark, .light
- Remove .child and .elder cases
- Rename DarkTheme struct → DarkTheme
- Rename LightTheme struct → LightTheme
- DELETE LightTheme struct (lines ~136-167)
- DELETE LightTheme struct (lines ~169-200)
- Update ThemeFactory.theme(for:) to handle only dark/light
- Update displayName and icon for AppTheme
- Update ThemedView.colorScheme(for:) - handle only dark/light
- Remove persona-specific protocol properties if no longer needed
Key visual differences to maintain:
- Dark: Black background (#000000), white text, indigo accent
- Light: White background (#FFFFFF), black text, indigo accent
---
2. familyplus/familyplus/ContentView.swift
Changes:
- Rename ThemeWrapper enum to ThemeMode with .dark and .light only
- Remove .child and .elder cases
- Update ThemeManager.setPersona() → setTheme()
- DELETE ChildMainTabView struct (lines ~163-224)
- DELETE ElderMainTabView struct (lines ~226-291)
- DELETE PersonaSwitcher (lines ~293-338)
- DELETE PersonaPickerView (lines ~341-398)
- DELETE PersonaCard (lines ~400-431)
- Add simple ThemeToggleView with sun/moon toggle
- Update MainNavigationFlow to use only Dark/Light main tab views
- Keep single standard MainTabView that works for both themes
---
3. familyplus/familyplus/MainAppView.swift
Changes:
- DELETE Teen/Parent/Child/Elder navigation switches (lines ~35-60)
- DELETE TeenNavigation struct (lines ~67-132)
- DELETE ParentNavigation struct (lines ~134-176)
- DELETE ChildNavigation struct (lines ~178-224)
- DELETE ElderNavigation struct (lines ~226-245)
- Create single MainNavigation with standard TabView
- Update currentTheme property to use AppTheme enum
- Remove profile array (no longer needed)
- Simplify to use theme toggle instead
---
📱 Screens
4. familyplus/familyplus/Screens/HubView.swift
Changes:
- DELETE ChildDashboard struct (lines ~307-347)
- DELETE ElderDashboard struct (lines ~372-397)
- DELETE ChildDashboardContent struct (lines ~350-370)
- DELETE ElderDashboardContent struct (lines ~399-440)
- DELETE ChildHeroSection struct (lines ~883-918)
- DELETE ChildUnheardSection struct (lines ~920-935)
- DELETE ChildUnheardCard struct (lines ~937-987)
- DELETE ElderHeroSection struct (lines ~989-1025)
- DELETE ElderUpcomingCallSection struct (lines ~1027-1063)
- DELETE TeenDashboardContent and ParentDashboardContent (merge to single DashboardContent)
- Simplify HubView to use single dashboard layout (scroll for dark, grid for light)
- Remove all switch statements on theme.role for child/elder
- Remove UnheardVoice.role property or simplify
- Update sample data to remove child/elder profiles
- Remove storyteller color switches for child/elder in UnheardVoiceCard
Simplified HubView structure:
struct HubView: View {
    @Environment(\.theme) var theme
    @State private var currentTheme: AppTheme = .light
    // ... states ...
    
    var body: some View {
        // Show grid for light, scroll for dark
        if currentTheme == .dark {
            DarkDashboard()
        } else {
            LightDashboard()
        }
    }
}
---
5. familyplus/familyplus/Screens/ProfileView.swift
Changes:
- Remove switch on theme.role for layout (lines ~18-25)
- Remove storyteller color switches for child/elder (lines ~256-259, 471-474)
- Update sample family members (remove Grandma and Mia)
---
6. familyplus/familyplus/Screens/StudioView.swift
Changes:
- Remove switch on theme.role for layout (lines ~31-59)
- Remove switch on theme.role for recording UI (lines ~1322-1329)
---
7. familyplus/familyplus/Screens/StoryDetailView.swift
Changes:
- Remove switch on theme.role for layout (lines ~158-175)
- Remove storyteller color switches for child/elder (lines ~100-106)
---
8. familyplus/familyplus/Screens/MyFamilyView.swift
Changes:
- Remove switch on theme.role for layout (lines ~39-66)
- Remove .elder specific views (line 416)
- Update sample family members
---
9. familyplus/familyplus/Screens/AddPerspectiveView.swift
Changes:
- Remove switch on theme.role for layout (lines ~74-123)
---
🧩 Components
10. familyplus/familyplus/Components/ProfileSwitcher.swift → ThemeToggle.swift
Changes:
- DELETE entire file
- Create new ThemeToggle.swift with simple sun/moon toggle button
New ThemeToggle design:
struct ThemeToggle: View {
    @Binding var currentTheme: AppTheme
    
    var body: some View {
        Button(action: {
            currentTheme = currentTheme == .dark ? .light : .dark
        }) {
            Image(systemName: currentTheme == .dark ? "sun.max.fill" : "moon.fill")
                .font(.title3)
        }
    }
}
---
11. familyplus/familyplus/Components/AdaptiveButton.swift
Changes:
- Remove switch on theme.role for button styles (lines ~31-67)
- Simplify to single button style (use Parent as baseline)
- Remove child-specific touch targets and font sizes
- Remove haptic intensity differences based on child
---
12. familyplus/familyplus/Components/StoryCard.swift
Changes:
- Remove storytellerRole: PersonaRole property (or keep as metadata)
- Remove switch on storytellerRole for colors (lines ~23-29)
- Simplify to use storyteller colors based on something else or remove
- Remove switch on theme.role for card layout (lines ~89-96)
---
13. familyplus/familyplus/Components/FamilyGovernance.swift
Changes:
- Remove all persona role references
- This component might need complete rethinking or deletion if it was persona-specific
---
14. familyplus/familyplus/Components/MemoryContextPanel.swift
Changes:
- Remove Contributor.role property or keep as metadata
- Remove roleDisplayName() switch for elder (lines ~184-189)
- Update sample contributors (remove Grandma)
---
🗄️ Database/Backend
15. familyplus/familyplus/Services/SupabaseService.swift
Changes:
- Remove personaRole computed property (lines ~132-138)
- Update any API calls that send persona data
---
New Files to Create
familyplus/familyplus/Components/ThemeToggle.swift
Simple sun/moon toggle for theme switching.
---
Design Decisions to Clarify
1. Layout Difference Between Dark/Light?
Question: Should dark mode use scroll and light mode use grid (like Teen/Parent), or should they have the same layout?
Recommendation: Use same layout for both, just different theming. Simpler to maintain.
2. Storyteller Colors
Question: What should determine storyteller colors if not persona roles?
Options:
a. Keep using colors but assign randomly or based on user
b. Remove storyteller colors entirely
c. Use user's choice/color picker
Recommendation: Keep using storyteller colors but assign based on user ID or random assignment.
3. Theme Persistence
Question: How should the user's theme preference be saved?
Recommendation: Use UserDefaults with key userThemePreference.
4. Family Member Roles
Question: Should we remove the concept of family member roles entirely from the data model?
Recommendation: Keep as metadata for API/backend, but don't use for UI decisions.
---
Testing Checklist
After refactoring, verify:
- [ ] App launches and shows default theme (light)
- [ ] Theme toggle switches between dark/light correctly
- [ ] All screens display correctly in both themes
- [ ] Navigation works in both themes
- [ ] No compilation errors
- [ ] No runtime crashes
- [ ] Story cards display correctly
- [ ] Profile view works
- [ ] Studio/recording view works
- [ ] Build succeeds for all targets
---
Migration Strategy
1. Start with core theme files - Update PersonaTheme.swift first
2. Then update navigation - Update ContentView.swift and MainAppView.swift
3. Then update screens one by one - HubView, ProfileView, etc.
4. Then update components - Remove ProfileSwitcher, update others
5. Finally update backend/services - SupabaseService.swift
---
Estimated Complexity
- Low: Simple file renames and enum case deletions
- Medium: Consolidating multiple dashboard layouts into one or two
- High: Updating all switch statements across 16 files
- Risk: Deleting too much and breaking functionality
---