import SwiftUI

struct FamilyNameScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var familyName = ""
    @State private var isCreating = false
    @FocusState private var isFocused: Bool
    
    private let suggestions = ["The Smiths", "Smith Family", "Casa Smith", "Team Smith"]
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(theme.accentColor.opacity(0.1))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "house.fill")
                            .font(.system(size: 44))
                            .foregroundColor(theme.accentColor)
                    }
                    .opacity(showContent ? 1 : 0)
                    .scaleEffect(showContent ? 1 : 0.8)
                    
                    VStack(spacing: 12) {
                        Text("Name Your Family")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(theme.textColor)
                        
                        Text("This will be your shared story space")
                            .font(.system(size: 17))
                            .foregroundColor(theme.secondaryTextColor)
                    }
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1 : 0)
                }
                
                Spacer()
                    .frame(height: 48)
                
                VStack(spacing: 20) {
                    TextField("", text: $familyName, prompt: Text("Enter family name").foregroundColor(theme.secondaryTextColor.opacity(0.6)))
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(theme.textColor)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 20)
                        .padding(.horizontal, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(theme.cardBackgroundColor)
                        )
                        .focused($isFocused)
                    
                    if familyName.isEmpty {
                        VStack(spacing: 8) {
                            Text("Suggestions")
                                .font(.system(size: 13))
                                .foregroundColor(theme.secondaryTextColor)
                            
                            HStack(spacing: 8) {
                                ForEach(suggestions.prefix(3), id: \.self) { suggestion in
                                    Button {
                                        familyName = suggestion
                                    } label: {
                                        Text(suggestion)
                                            .font(.system(size: 14))
                                            .foregroundColor(theme.accentColor)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule()
                                                    .fill(theme.accentColor.opacity(0.1))
                                            )
                                    }
                                }
                            }
                        }
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal, 24)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                
                Spacer()
                
                OnboardingCTAButton(
                    title: isCreating ? "Creating..." : "Continue",
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
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
        }
    }
}

#Preview {
    FamilyNameScreenView(coordinator: .preview)
        .themed(LightTheme())
}
