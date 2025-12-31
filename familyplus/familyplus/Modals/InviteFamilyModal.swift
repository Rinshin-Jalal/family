//
//  InviteFamilyModal.swift
//  StoryRide
//
//  Modal for inviting new family members
//

import SwiftUI

struct InviteFamilyModal: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var showSuccess = false
    
    var body: some View {
        ZStack {
            theme.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                if !showSuccess {
                    inviteForm
                } else {
                    successState
                }
                
                Spacer()
                
                dismissButton
            }
            .padding(.horizontal, theme.screenPadding)
        }
    }
    
    private var inviteForm: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(theme.accentColor)
            
            VStack(spacing: 12) {
                Text("Invite Family Member")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(theme.textColor)
                
                Text("Share your invite link\nto add someone new")
                    .font(.system(size: 16))
                    .foregroundColor(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
            
            TextField("", text: $email)
                .font(.system(size: 18))
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.cardBackgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(theme.accentColor, lineWidth: 2)
                )
                .overlay(
                    Group {
                        if email.isEmpty {
                            Text("Enter email address")
                                .foregroundColor(theme.secondaryTextColor)
                                .padding(.leading, 20)
                        }
                    },
                    alignment: .leading
                )
            
            Button(action: {
                withAnimation {
                    showSuccess = true
                }
            }) {
                Text("Send Invite")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: theme.buttonHeight)
                    .background(theme.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(email.isEmpty)
            .opacity(email.isEmpty ? 0.5 : 1.0)
        }
    }
    
    private var successState: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Invite Sent!")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(theme.textColor)
            
            Text("Check your email for invite link")
                .font(.system(size: 16))
                .foregroundColor(theme.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
    }
    
    private var dismissButton: some View {
        Button(action: {
            dismiss()
        }) {
            Text(showSuccess ? "Done" : "Cancel")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(theme.accentColor)
                .frame(maxWidth: .infinity)
                .frame(height: theme.buttonHeight)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(theme.accentColor, lineWidth: 2)
                )
        }
    }
}

// MARK: - Preview

struct InviteFamilyModal_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            InviteFamilyModal()
                .themed(DarkTheme())
                .previewDisplayName("Dark Theme")
            
            InviteFamilyModal()
                .themed(LightTheme())
                .previewDisplayName("Light Theme")
        }
    }
}
