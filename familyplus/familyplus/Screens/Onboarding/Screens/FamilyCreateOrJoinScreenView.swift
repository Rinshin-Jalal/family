import SwiftUI

struct FamilyCreateOrJoinScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var selectedOption: SelectionOption? = nil
    @State private var familyName = ""
    @State private var inviteCode = ""
    @State private var isCreating = false
    @State private var isJoining = false
    @FocusState private var focusedField: FocusField?
    
    private enum SelectionOption {
        case create, join
    }
    
    private enum FocusField {
        case familyName, inviteCode
    }
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 60)
                    
                    VStack(spacing: 16) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 56))
                            .foregroundColor(theme.accentColor)
                            .opacity(showContent ? 1 : 0)
                            .scaleEffect(showContent ? 1 : 0.5)
                        
                        Text("Your Family Space")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(theme.textColor)
                            .opacity(showContent ? 1 : 0)
                        
                        Text("Start fresh or join your family")
                            .font(.system(size: 17))
                            .foregroundColor(theme.secondaryTextColor)
                            .opacity(showContent ? 1 : 0)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 40)
                    
                    VStack(spacing: 16) {
                        FamilyOptionCard(
                            icon: "plus.circle.fill",
                            title: "Create New Family",
                            subtitle: "Start your family's story collection",
                            isSelected: selectedOption == .create,
                            action: {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedOption = .create
                                    focusedField = .familyName
                                }
                            }
                        )
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                        
                        if selectedOption == .create {
                            VStack(spacing: 16) {
                                TextField("", text: $familyName, prompt: Text("Enter family name").foregroundColor(theme.secondaryTextColor.opacity(0.6)))
                                    .font(.system(size: 18))
                                    .foregroundColor(theme.textColor)
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(theme.cardBackgroundColor)
                                    )
                                    .focused($focusedField, equals: .familyName)
                                
                                OnboardingCTAButton(
                                    title: isCreating ? "Creating..." : "Create Family",
                                    action: {
                                        guard !familyName.isEmpty else { return }
                                        isCreating = true
                                        Task {
                                            await coordinator.createFamily(name: familyName)
                                            isCreating = false
                                        }
                                    }
                                )
                                .disabled(familyName.isEmpty || isCreating)
                                .opacity(familyName.isEmpty ? 0.6 : 1)
                            }
                            .padding(.horizontal, 4)
                            .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .top)), removal: .opacity))
                        }
                        
                        HStack {
                            Rectangle()
                                .fill(theme.secondaryTextColor.opacity(0.2))
                                .frame(height: 1)
                            
                            Text("or")
                                .font(.system(size: 14))
                                .foregroundColor(theme.secondaryTextColor)
                                .padding(.horizontal, 12)
                            
                            Rectangle()
                                .fill(theme.secondaryTextColor.opacity(0.2))
                                .frame(height: 1)
                        }
                        .padding(.vertical, 8)
                        .opacity(showContent ? 1 : 0)
                        
                        FamilyOptionCard(
                            icon: "person.badge.plus",
                            title: "Join Existing Family",
                            subtitle: "Enter a code from your family member",
                            isSelected: selectedOption == .join,
                            action: {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedOption = .join
                                    focusedField = .inviteCode
                                }
                            }
                        )
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                        
                        if selectedOption == .join {
                            VStack(spacing: 16) {
                                TextField("", text: $inviteCode, prompt: Text("Enter invite code").foregroundColor(theme.secondaryTextColor.opacity(0.6)))
                                    .font(.system(size: 18, design: .monospaced))
                                    .foregroundColor(theme.textColor)
                                    .textInputAutocapitalization(.characters)
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(theme.cardBackgroundColor)
                                    )
                                    .focused($focusedField, equals: .inviteCode)
                                
                                OnboardingCTAButton(
                                    title: isJoining ? "Joining..." : "Join Family",
                                    action: {
                                        guard !inviteCode.isEmpty else { return }
                                        isJoining = true
                                        Task {
                                            await coordinator.joinFamily(code: inviteCode)
                                            isJoining = false
                                        }
                                    }
                                )
                                .disabled(inviteCode.isEmpty || isJoining)
                                .opacity(inviteCode.isEmpty ? 0.6 : 1)
                            }
                            .padding(.horizontal, 4)
                            .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .top)), removal: .opacity))
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                        .frame(height: 60)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
        }
    }
}

private struct FamilyOptionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? theme.accentColor : theme.accentColor.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? .white : theme.accentColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(theme.textColor)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(theme.secondaryTextColor)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? theme.accentColor : theme.secondaryTextColor.opacity(0.3))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.cardBackgroundColor)
                    .shadow(color: isSelected ? theme.accentColor.opacity(0.2) : .black.opacity(0.05), radius: isSelected ? 12 : 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? theme.accentColor : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FamilyCreateOrJoinScreenView(coordinator: .preview)
        .themed(LightTheme())
}
