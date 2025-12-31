//
//  ReactionPickerModal.swift
//  StoryRide
//
//  Modal view for selecting reactions to stories
//

import SwiftUI

// MARK: - Reaction Picker Modal

struct ReactionPickerModal: View {
    @Binding var selectedReaction: Reaction?
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var theme
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("React to this story")
                    .font(theme.headlineFont)
                    .padding(.top)
                
                HStack(spacing: 20) {
                    ForEach(Reaction.allCases, id: \.self) { reaction in
                        Button(action: {
                            selectedReaction = reaction
                            dismiss()
                        }) {
                            Text(reaction.rawValue)
                                .font(.system(size: 48))
                        }
                        .accessibilityLabel(reaction.accessibilityLabel)
                    }
                }
                .padding()
                
                Spacer()
            }
            .background(theme.backgroundColor)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(theme.accentColor)
                    .font(.system(size: 17, weight: .semibold))
                }
            }
        }
    }
}

// MARK: - Preview

struct ReactionPickerModal_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ReactionPickerModal(selectedReaction: .constant(nil))
                .themed(DarkTheme())
                .previewDisplayName("Dark Theme")
            
            ReactionPickerModal(selectedReaction: .constant(.heart))
                .themed(LightTheme())
                .previewDisplayName("Light Theme")
        }
    }
}
