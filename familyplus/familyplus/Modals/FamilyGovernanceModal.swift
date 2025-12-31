//
//  FamilyGovernanceModal.swift
//  StoryRide
//
//  Modal for family governance and safety controls
//

import SwiftUI

// MARK: - Family Data Model

struct FamilyData {
    let id: String
    let name: String
    let memberCount: Int
    let storyCount: Int
    let ownerId: String
    let createdAt: Date
    var hasSensitiveTopics: Bool
    var allowsConflictingPerspectives: Bool
}

// MARK: - Family Governance Modal

struct FamilyGovernanceModal: View {
    let familyData: FamilyData
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header message
                    VStack(spacing: 12) {
                        Text("🛡️")
                            .font(.system(size: 64))
                        
                        Text("Family Governance")
                            .font(.title.bold())
                            .foregroundColor(theme.textColor)
                        
                        Text("Understanding how your family works together safely")
                            .font(.subheadline)
                            .foregroundColor(theme.secondaryTextColor)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 24)
                    
                    // Trust indicators
                    VStack(alignment: .leading, spacing: 12) {
                        if familyData.hasSensitiveTopics {
                            TrustIndicator(
                                icon: "checkmark.shield.fill",
                                text: "Sensitive topics handled with care",
                                color: .green
                            )
                        }
                        
                        if familyData.allowsConflictingPerspectives {
                            TrustIndicator(
                                icon: "checkmark.circle.fill",
                                text: "Different perspectives welcome - we never label truth",
                                color: .blue
                            )
                        }
                        
                        TrustIndicator(
                            icon: "lock.fill",
                            text: "Your memories belong to the family, not the app",
                            color: .purple
                        )
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                    )
                    
                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Trust Indicator

struct TrustIndicator: View {
    let icon: String
    let text: String
    let color: Color
    @Environment(\.theme) var theme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(theme.textColor)
            
            Spacer()
        }
    }
}

// MARK: - Preview

struct FamilyGovernanceModal_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FamilyGovernanceModal(familyData: FamilyData(
                id: "family-123",
                name: "The Rodriguez Family",
                memberCount: 4,
                storyCount: 42,
                ownerId: "user-1",
                createdAt: Date(),
                hasSensitiveTopics: true,
                allowsConflictingPerspectives: true
            ))
            .themed(DarkTheme())
            .previewDisplayName("Dark Theme")
            
            FamilyGovernanceModal(familyData: FamilyData(
                id: "family-456",
                name: "Smith Family",
                memberCount: 3,
                storyCount: 15,
                ownerId: "user-2",
                createdAt: Date(),
                hasSensitiveTopics: false,
                allowsConflictingPerspectives: false
            ))
            .themed(LightTheme())
            .previewDisplayName("Light Theme")
        }
    }
}
