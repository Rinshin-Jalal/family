import SwiftUI

struct PitchHowItWorksCollectionScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var selectedMethod: Int? = nil
    
    private let methods: [(icon: String, title: String, description: String, color: Color)] = [
        ("mic.fill", "Voice", "Record conversations naturally", Color.storytellerElder),
        ("text.quote", "Written", "Type or dictate stories", Color.storytellerParent),
        ("photo.fill", "Photos", "Add context to memories", Color.storytellerTeen),
        ("phone.fill", "Phone AI", "Auto-interviews elders", Color.storytellerChild)
    ]
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "rectangle.stack.fill")
                        .font(.system(size: 48))
                        .foregroundColor(theme.accentColor)
                        .opacity(showContent ? 1 : 0)
                        .scaleEffect(showContent ? 1 : 0.5)
                    
                    Text("Four Ways to Collect")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(theme.textColor)
                        .opacity(showContent ? 1 : 0)
                    
                    Text("Use whatever feels natural")
                        .font(.system(size: 17))
                        .foregroundColor(theme.secondaryTextColor)
                        .opacity(showContent ? 1 : 0)
                }
                .multilineTextAlignment(.center)
                
                Spacer()
                    .frame(height: 40)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(Array(methods.enumerated()), id: \.offset) { index, method in
                        CollectionMethodCard(
                            icon: method.icon,
                            title: method.title,
                            description: method.description,
                            color: method.color,
                            isSelected: selectedMethod == index,
                            delay: Double(index) * 0.1
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                selectedMethod = selectedMethod == index ? nil : index
                            }
                        }
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 30)
                        .animation(.easeOut(duration: 0.5).delay(Double(index) * 0.1), value: showContent)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                Text("Mix and match—every story matters")
                    .font(.system(size: 15))
                    .foregroundColor(theme.secondaryTextColor)
                    .opacity(showContent ? 1 : 0)
                    .padding(.bottom, 16)
                
                OnboardingCTAButton(
                    title: "Continue",
                    action: { coordinator.goToNextStep() }
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
        }
    }
}

private struct CollectionMethodCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let isSelected: Bool
    let delay: Double
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(isSelected ? 0.2 : 0.1))
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(theme.textColor)
            
            Text(description)
                .font(.system(size: 13))
                .foregroundColor(theme.secondaryTextColor)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackgroundColor)
                .shadow(color: isSelected ? color.opacity(0.3) : .black.opacity(0.05), radius: isSelected ? 12 : 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? color : .clear, lineWidth: 2)
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
    }
}

#Preview {
    PitchHowItWorksCollectionScreenView(coordinator: .preview)
        .themed(LightTheme())
}
