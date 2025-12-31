Critical HIG Violations
1. Both Input Methods Visible (User's Point)
// ❌ Current: Both shown simultaneously
TextField("How do you remember this?", text: $perspectiveText)
Button("Record Voice") // Always visible
// ✅ Should be: One at a time, toggled via segmented picker
HIG Rule: Show one input method at a time. Use .pickerStyle(.segmented) for 2-option choice.
---
2. Submit Button Disabled Logic Wrong
.disabled(perspectiveText.isEmpty) // ❌ Only checks text, ignores voice
If user records voice, text stays empty → button stays disabled.
HIG Rule: Submit should enable when EITHER text OR voice has input.
---
3. Sheet Presentation Missing Detents
// ❌ Missing presentation configuration
.sheet(isPresented: $showPerspectiveModal) {
    PerspectiveModal()
}
// ✅ Should specify detents
.sheet(isPresented: $showPerspectiveModal) {
    PerspectiveModal()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
}
HIG Rule: Medium detent for simple input, large for complex content. Show drag indicator.
---
4. Hardcoded Color Instead of Semantic
.background(Color.blue) // ❌ Hardcoded
.foregroundColor(.blue) // ❌ Hardcoded
// ✅ Should use
.background(Color.accentColor) // System accent
HIG Rule: Use .accentColor or semantic colors for proper dark mode adaptation.
---
5. Cancel Button Wrong Position
ToolbarItem(placement: .navigationBarLeading) // ❌ Leading
// ✅ Should be trailing
ToolbarItem(placement: .navigationBarTrailing)
HIG Rule: Cancel/Close goes on trailing side for sheets.
---
6. Non-Standard Button Styling
Button(action: submitPerspective) {
    Text("Add Perspective")
        .foregroundColor(.white)
        .background(Color.blue)
        .clipShape(RoundedRectangle(cornerRadius: 16))
} // ❌ Custom styling
// ✅ Standard HIG style
Button("Add Perspective", action: submitPerspective)
    .buttonStyle(.borderedProminent)
    .disabled(!canSubmit)
HIG Rule: Use .borderedProminent for primary action, .bordered for secondary.
---
7. TextField Not Using Standard Style
TextField("How do you remember this?", text: $perspectiveText, axis: .vertical)
    .textFieldStyle(.plain) // ❌ No style
    .background(Color(uiColor: .secondarySystemGroupedBackground))
// ✅ Should use
TextField("How do you remember this?", text: $perspectiveText)
    .textFieldStyle(.roundedBorder)
    .textContentType(.none)
HIG Rule: Use .roundedBorder or inline form style.
---
8. Spacing Not on 8pt Grid
.padding(.top, 40) // ❌ 40pt
.padding(.horizontal, 24) // ❌ 24pt
.padding(.vertical, 14) // ❌ 14pt
// ✅ Should be
.padding(.top, 32) // 8pt grid
.padding(.horizontal, 20) // 8pt grid
.padding(.vertical, 12) // 8pt grid
HIG Rule: All spacing must be multiples of 8.
---
9. Missing Accessibility Labels
Button(action: { isRecording.toggle() }) {
    HStack {
        Image(systemName: "mic.circle.fill")
        Text("Record Voice")
    }
} // ❌ No accessibilityLabel
// ✅ Should have
Button(action: { isRecording.toggle() }) {
    HStack {
        Image(systemName: "mic.circle.fill")
        Text("Record Voice")
    }
}
.accessibilityLabel(isRecording ? "Stop recording" : "Start recording")
HIG Rule: All interactive elements need .accessibilityLabel().
---
10. Custom Story Selection - Not HIG Compliant
ScrollView(.horizontal, showsIndicators: false) {
    HStack(spacing: 16) {
        ForEach(stories) { story in
            StoryBubbleCard(...) // Custom card
        }
    }
} // ❌ Custom scrolling cards
// ✅ Should use Picker
Picker("Story", selection: $selectedStory) {
    ForEach(stories) { story in
        Text(story.title).tag(story)
    }
}
.pickerStyle(.menu)
HIG Rule: Use standard Picker for selection, not custom horizontal scroll.
---
Recommended HIG-Compliant Redesign
struct PerspectiveModal: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedStory: Story?
    @State private var perspectiveText = ""
    @State private var isRecording = false
    @State private var inputMethod: InputMethod = .text
    
    enum InputMethod: String, CaseIterable {
        case text = "Text"
        case voice = "Voice"
    }
    
    var canSubmit: Bool {
        if case .text = inputMethod {
            return !perspectiveText.isEmpty && selectedStory != nil
        } else {
            return isRecording && selectedStory != nil
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Story", selection: $selectedStory) {
                        ForEach(stories) { story in
                            Label(story.title, systemImage: "doc.text")
                                .tag(story)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Choose a story")
                }
                
                if selectedStory != nil {
                    Section {
                        Picker("Input Method", selection: $inputMethod) {
                            ForEach(InputMethod.allCases, id: \.self) { method in
                                Label(method.rawValue, systemImage: method == .text ? "text.alignleft" : "mic.fill")
                                    .tag(method)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    Section {
                        if inputMethod == .text {
                            TextField("Your perspective", text: $perspectiveText, axis: .vertical)
                                .lineLimit(3...6)
                                .textContentType(.none)
                        } else {
                            HStack {
                                Image(systemName: isRecording ? "record.circle.fill" : "mic.circle.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(isRecording ? .red : .primary)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(isRecording ? "Recording..." : "Tap to record")
                                        .font(.headline)
                                    
                                    Text(isRecording ? "Tap to stop" : "Your voice input")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                isRecording.toggle()
                            }
                            .accessibilityLabel(isRecording ? "Stop recording" : "Start recording")
                            .accessibilityAddTraits(.isButton)
                        }
                    } header: {
                        Text("Add your perspective")
                    }
                }
            }
            .navigationTitle("Perspective")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done", action: submitPerspective)
                        .disabled(!canSubmit)
                        .buttonStyle(.borderedProminent)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
            }
        }
        .interactiveDismissDisabled(isRecording)
    }
    
    private func submitPerspective() {
        dismiss()
    }
}
---
Key HIG Improvements Summary
| Issue | Current | HIG Compliant |
|--------|---------|----------------|
| Input methods | Both visible | Segmented picker (one at a time) |
| Submit logic | Text only | Text OR voice |
| Sheet detents | None | .medium, .large with drag indicator |
| Cancel position | Leading | Trailing (cancellationAction) |
| Button style | Custom | .borderedProminent |
| Text field style | Custom | .roundedBorder |
| Spacing | Random (40, 24, 14) | 8pt grid (32, 20, 12) |
| Selection | Custom scroll | Standard Picker |
| Accessibility | None | Labels everywhere |
| Color | Hardcoded .blue | .accentColor |
Want me to implement the HIG-compliant version?
