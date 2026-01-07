import SwiftUI

struct FamilyRoleScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var selectedRole: String? = nil
    
    private let roles: [(id: String, icon: String, title: String, subtitle: String)] = [
        ("parent", "figure.and.child.holdinghands", "Parent", "You're raising the next generation"),
        ("grandparent", "figure.2.arms.open", "Grandparent", "You have wisdom to share"),
        ("child", "face.smiling", "Child / Teen", "You're learning family history"),
        ("extended", "person.3.fill", "Extended Family", "Aunt, uncle, cousin, etc."),
        ("friend", "heart.fill", "Close Friend", "Family isn't just blood")
    ]
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 40)
                
                VStack(spacing: 16) {
                    Text("Your Role")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(theme.textColor)
                    
                    Text("How are you connected to this family?")
                        .font(.system(size: 17))
                        .foregroundColor(theme.secondaryTextColor)
                }
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : -20)
                
                Spacer()
                    .frame(height: 32)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(Array(roles.enumerated()), id: \.element.id) { index, role in
                            RoleOptionButton(
                                icon: role.icon,
                                title: role.title,
                                subtitle: role.subtitle,
                                isSelected: selectedRole == role.id,
                                action: {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedRole = role.id
                                    }
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        coordinator.setUserRole(role.title, name: coordinator.onboardingState.userName)
                                        coordinator.goToNextStep()
                                    }
                                }
                            )
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                            .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.08), value: showContent)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer()
                    .frame(height: 20)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
        }
    }
}

private struct RoleOptionButton: View {
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
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .white : theme.accentColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.textColor)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(theme.secondaryTextColor)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.secondaryTextColor.opacity(0.5))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.cardBackgroundColor)
                    .shadow(color: isSelected ? theme.accentColor.opacity(0.2) : .black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? theme.accentColor : .clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FamilyRoleScreenView(coordinator: .preview)
        .themed(LightTheme())
}
