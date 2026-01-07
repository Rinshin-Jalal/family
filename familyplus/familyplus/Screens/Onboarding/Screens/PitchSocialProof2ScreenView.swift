import SwiftUI

struct PitchSocialProof2ScreenView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.theme) private var theme
    
    @State private var showContent = false
    @State private var currentTestimonial = 0
    
    private let testimonials: [(quote: String, name: String, relation: String)] = [
        ("I finally have my grandmother's recipes in her own voice. My kids can hear her laugh whenever they want.", "Sarah M.", "Granddaughter"),
        ("Dad passed last year, but his stories live on. Best gift we ever gave ourselves.", "Michael T.", "Son"),
        ("We recorded 47 stories in one weekend. My parents couldn't stop once they started!", "Jennifer L.", "Daughter"),
        ("My 8-year-old now knows her great-grandpa through his stories. That's priceless.", "David K.", "Father")
    ]
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 40))
                        .foregroundColor(theme.accentColor.opacity(0.3))
                        .opacity(showContent ? 1 : 0)
                    
                    Text("Real Families,\nReal Stories")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(theme.textColor)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                }
                
                Spacer()
                    .frame(height: 40)
                
                TabView(selection: $currentTestimonial) {
                    ForEach(Array(testimonials.enumerated()), id: \.offset) { index, testimonial in
                        TestimonialCard(
                            quote: testimonial.quote,
                            name: testimonial.name,
                            relation: testimonial.relation
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 260)
                .opacity(showContent ? 1 : 0)
                
                HStack(spacing: 8) {
                    ForEach(0..<testimonials.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentTestimonial ? theme.accentColor : theme.accentColor.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: currentTestimonial)
                    }
                }
                .padding(.top, 16)
                .opacity(showContent ? 1 : 0)
                
                Spacer()
                
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
            
            Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentTestimonial = (currentTestimonial + 1) % testimonials.count
                }
            }
        }
    }
}

private struct TestimonialCard: View {
    let quote: String
    let name: String
    let relation: String
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 20) {
            Text(quote)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(theme.textColor)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
            
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.yellow)
                    }
                }
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(theme.accentColor.opacity(0.2))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text(String(name.prefix(1)))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(theme.accentColor)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(theme.textColor)
                        
                        Text(relation)
                            .font(.system(size: 13))
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.cardBackgroundColor)
                .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 8)
        )
        .padding(.horizontal, 24)
    }
}

#Preview {
    PitchSocialProof2ScreenView(coordinator: .preview)
        .themed(LightTheme())
}
