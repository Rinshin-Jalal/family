//
//  SubscriptionView.swift
//  StoryRide
//
//  Subscription UI - Manage subscriptions and feature gating
//

import SwiftUI
import Combine

// MARK: - Subscription Models

enum SubscriptionTier: String, CaseIterable, Codable {
    case free = "free"
    case basic = "basic"
    case family = "family"
    
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .basic: return "Basic"
        case .family: return "Family"
        }
    }
    
    var price: String {
        switch self {
        case .free: return "$0"
        case .basic: return "$4.99/mo"
        case .family: return "$9.99/mo"
        }
    }
    
    var features: [String] {
        switch self {
        case .free:
            return ["5 stories per month", "Basic search", "2 family members", "Standard support"]
        case .basic:
            return ["Unlimited stories", "AI wisdom summaries", "Quote cards", "5 family members", "Priority support", "Cartoon generator"]
        case .family:
            return ["Everything in Basic", "Unlimited family members", "Kids mode", "Advanced analytics", "Dedicated support", "API access", "Custom branding"]
        }
    }
    
    var icon: String {
        switch self {
        case .free: return "star"
        case .basic: return "star.fill"
        case .family: return "crown.fill"
        }
    }
}

struct SubscriptionStatus: Codable {
    let currentTier: SubscriptionTier
    let isActive: Bool
    let renewDate: Date?
    let cancelDate: Date?
    let paymentMethod: String?
    let usageThisMonth: Int
    let limit: Int
}

struct PricingPlan: Identifiable, Codable {
    let id: String
    let name: String
    let priceMonthly: Double
    let priceYearly: Double
    let features: [String]
    let isPopular: Bool
    let savingsPercent: Int?
}

// MARK: - Subscription View

struct SubscriptionView: View {
    @State private var subscriptionStatus = SubscriptionStatus(
        currentTier: .free,
        isActive: true,
        renewDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
        cancelDate: nil,
        paymentMethod: "•••• 4242",
        usageThisMonth: 3,
        limit: 5
    )
    @State private var selectedPlan: PricingPlan?
    @State private var showUpgrade = false
    @State private var billingCycle: BillingCycle = .monthly
    
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss
    
    enum BillingCycle: String, CaseIterable {
        case monthly = "Monthly"
        case yearly = "Yearly"
        
        var discount: Double {
            switch self {
            case .monthly: return 1.0
            case .yearly: return 0.83 // 17% discount
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Current Status Card
                    CurrentSubscriptionCard(status: subscriptionStatus) {
                        showUpgrade = true
                    }
                    
                    // Usage Progress
                    if subscriptionStatus.currentTier == .free {
                        UsageProgressCard(used: subscriptionStatus.usageThisMonth, limit: subscriptionStatus.limit)
                    }
                    
                    // Pricing Plans
                    PricingPlansSection(
                        selectedPlan: $selectedPlan,
                        billingCycle: $billingCycle,
                        onSelectPlan: { plan in
                            selectedPlan = plan
                            showUpgrade = true
                        }
                    )
                    
                    // Feature Comparison
                    FeatureComparisonSection()
                    
                    // FAQ Section
                    FAQSection()
                }
                .padding(.vertical)
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationTitle("Subscription")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showUpgrade) {
                if let plan = selectedPlan {
                    UpgradePaymentSheet(plan: plan, billingCycle: billingCycle)
                }
            }
        }
    }
}

// MARK: - Current Subscription Card

struct CurrentSubscriptionCard: View {
    let status: SubscriptionStatus
    let onUpgrade: () -> Void
    
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(status.currentTier.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.textColor)
                    
                    if status.isActive {
                        Text("Active")
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                
                Spacer()
                
                Image(systemName: status.currentTier.icon)
                    .font(.largeTitle)
                    .foregroundColor(theme.accentColor)
            }
            
            if let renewDate = status.renewDate {
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Renews")
                            .font(.caption)
                            .foregroundColor(theme.secondaryTextColor)
                        Text(renewDate, style: .date)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(theme.textColor)
                    }
                    
                    Spacer()
                    
                    Button("Upgrade") {
                        onUpgrade()
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(theme.accentColor)
                    .clipShape(Capsule())
                }
            }
            
            if let paymentMethod = status.paymentMethod {
                HStack {
                    Image(systemName: "creditcard.fill")
                        .foregroundColor(theme.secondaryTextColor)
                    Text(paymentMethod)
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                    Spacer()
                    Button("Manage") {
                        // Open payment management
                    }
                    .font(.caption)
                    .foregroundColor(theme.accentColor)
                }
            }
        }
        .padding()
        .background(theme.cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

// MARK: - Usage Progress Card

struct UsageProgressCard: View {
    let used: Int
    let limit: Int
    
    @Environment(\.theme) var theme
    
    var progress: Double {
        min(Double(used) / Double(limit), 1.0)
    }
    
    var progressColor: Color {
        if progress >= 0.9 { return .red }
        if progress >= 0.7 { return .orange }
        return theme.accentColor
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(progressColor)
                Text("Usage This Month")
                    .font(.headline)
                Spacer()
                Text("\(used)/\(limit) stories")
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryTextColor)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
            
            if progress >= 0.8 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("You're running low on free stories. Upgrade to continue recording!")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(theme.cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

// MARK: - Pricing Plans Section

struct PricingPlansSection: View {
    @Binding var selectedPlan: PricingPlan?
    @Binding var billingCycle: SubscriptionView.BillingCycle
    let onSelectPlan: (PricingPlan) -> Void
    
    @Environment(\.theme) var theme
    
    let plans = [
        PricingPlan(id: "free", name: "Free", priceMonthly: 0, priceYearly: 0, features: ["5 stories/month", "Basic search", "2 family members"], isPopular: false, savingsPercent: nil),
        PricingPlan(id: "basic", name: "Basic", priceMonthly: 4.99, priceYearly: 49.99, features: ["Unlimited stories", "AI summaries", "Quote cards", "5 family members"], isPopular: true, savingsPercent: 17),
        PricingPlan(id: "family", name: "Family", priceMonthly: 9.99, priceYearly: 99.99, features: ["Everything in Basic", "Unlimited members", "Kids mode", "Analytics", "Priority support"], isPopular: false, savingsPercent: 17)
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            // Billing Cycle Toggle
            Picker("Billing", selection: $billingCycle) {
                ForEach(SubscriptionView.BillingCycle.allCases, id: \.self) { cycle in
                    Text(cycle.rawValue).tag(cycle)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            // Plans
            ForEach(plans) { plan in
                PricingPlanCard(
                    plan: plan,
                    billingCycle: billingCycle,
                    isSelected: selectedPlan?.id == plan.id,
                    onSelect: { onSelectPlan(plan) }
                )
            }
        }
    }
}

// MARK: - Pricing Plan Card

struct PricingPlanCard: View {
    let plan: PricingPlan
    let billingCycle: SubscriptionView.BillingCycle
    let isSelected: Bool
    let onSelect: () -> Void
    
    @Environment(\.theme) var theme
    
    var price: Double {
        billingCycle == .monthly ? plan.priceMonthly : plan.priceYearly
    }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 16) {
                if plan.isPopular {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("MOST POPULAR")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                    }
                    .padding(.top, 8)
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(theme.textColor)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("$\(price, specifier: "%.2f")")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(theme.textColor)
                            Text("/mo")
                                .font(.subheadline)
                                .foregroundColor(theme.secondaryTextColor)
                        }
                        
                        if let savings = plan.savingsPercent, billingCycle == .yearly {
                            Text("Save \(savings)%")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: plan.id == "family" ? "crown.fill" : (plan.id == "basic" ? "star.fill" : "star"))
                        .font(.title)
                        .foregroundColor(plan.isPopular ? theme.accentColor : .gray)
                }
                .padding(.horizontal)
                
                // Features
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(plan.features.prefix(3), id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text(feature)
                                .font(.caption)
                                .foregroundColor(theme.textColor)
                        }
                    }
                }
                .padding(.horizontal)
                
                // CTA Button
                Text(isSelected ? "Current Plan" : (plan.id == "free" ? "Current Plan" : "Upgrade"))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isSelected ? Color.gray : theme.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? theme.accentColor : Color.clear, lineWidth: 2)
                    )
            )
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Feature Comparison Section

struct FeatureComparisonSection: View {
    let features = [
        ("Stories per month", ["5", "Unlimited", "Unlimited"]),
        ("Family members", ["2", "5", "Unlimited"]),
        ("AI Wisdom", ["❌", "✅", "✅"]),
        ("Quote Cards", ["❌", "✅", "✅"]),
        ("Cartoon Generator", ["❌", "✅", "✅"]),
        ("Kids Mode", ["❌", "❌", "✅"]),
        ("Analytics", ["❌", "Basic", "Advanced"]),
        ("Priority Support", ["❌", "❌", "✅"])
    ]
    
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Feature Comparison")
                .font(.headline)
                .foregroundColor(theme.textColor)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    HStack(spacing: 0) {
                        Text("Feature")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(theme.secondaryTextColor)
                            .frame(width: 140, alignment: .leading)
                            .padding(8)
                        
                        ForEach(["Free", "Basic", "Family"], id: \.self) { tier in
                            Text(tier)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.textColor)
                                .frame(maxWidth: .infinity)
                                .padding(8)
                        }
                    }
                    .background(theme.cardBackgroundColor.opacity(0.5))
                    
                    // Rows
                    ForEach(features, id: \.0) { feature in
                        HStack(spacing: 0) {
                            Text(feature.0)
                                .font(.caption)
                                .foregroundColor(theme.textColor)
                                .frame(width: 140, alignment: .leading)
                                .padding(8)
                            
                            ForEach(feature.1, id: \.self) { value in
                                Text(value)
                                    .font(.caption)
                                    .foregroundColor(value.contains("✅") ? .green : (value.contains("❌") ? .red : theme.textColor))
                                    .frame(maxWidth: .infinity)
                                    .padding(8)
                            }
                        }
                        .background(theme.cardBackgroundColor.opacity(0.3))
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal)
    }
}

// MARK: - FAQ Section

struct FAQSection: View {
    let faqs = [
        ("Can I switch plans anytime?", "Yes, you can upgrade or downgrade your plan at any time. Changes take effect immediately."),
        ("Is there a free trial?", "We offer a 7-day free trial for Basic and Family plans."),
        ("What payment methods do you accept?", "We accept all major credit cards, Apple Pay, and Google Pay."),
        ("Can I cancel my subscription?", "Yes, you can cancel anytime. You'll continue to have access until the end of your billing period.")
    ]
    
    @Environment(\.theme) var theme
    @State private var expandedFAQ: Int?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Frequently Asked Questions")
                .font(.headline)
                .foregroundColor(theme.textColor)
                .padding(.horizontal)
            
            ForEach(Array(faqs.enumerated()), id: \.offset) { index, faq in
                FAQItem(
                    question: faq.0,
                    answer: faq.1,
                    isExpanded: expandedFAQ == index,
                    onTap: {
                        withAnimation {
                            if expandedFAQ == index {
                                expandedFAQ = nil
                            } else {
                                expandedFAQ = index
                            }
                        }
                    }
                )
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - FAQ Item

struct FAQItem: View {
    let question: String
    let answer: String
    let isExpanded: Bool
    let onTap: () -> Void
    
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onTap) {
                HStack {
                    Text(question)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.textColor)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                Text(answer)
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(theme.cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Upgrade Payment Sheet

struct UpgradePaymentSheet: View {
    let plan: PricingPlan
    let billingCycle: SubscriptionView.BillingCycle
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) var theme
    
    @State private var paymentMethod = "•••• 4242"
    @State private var isProcessing = false
    
    var price: Double {
        billingCycle == .monthly ? plan.priceMonthly : plan.priceYearly
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Plan Summary
                    VStack(spacing: 8) {
                        Image(systemName: plan.id == "family" ? "crown.fill" : (plan.id == "basic" ? "star.fill" : "star"))
                            .font(.largeTitle)
                            .foregroundColor(theme.accentColor)
                        
                        Text(plan.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack(alignment: .firstTextBaseline) {
                            Text("$\(price, specifier: "%.2f")")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("/mo")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    
                    Divider()
                    
                    // Payment Method
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Payment Method")
                            .font(.headline)
                        
                        HStack {
                            Image(systemName: "creditcard.fill")
                                .foregroundColor(theme.accentColor)
                            Text(paymentMethod)
                            Spacer()
                            Button("Change") {
                                // Open payment method selection
                            }
                            .font(.caption)
                            .foregroundColor(theme.accentColor)
                        }
                        .padding()
                        .background(theme.cardBackgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    
                    // Order Summary
                    VStack(spacing: 8) {
                        HStack {
                            Text(plan.name)
                            Spacer()
                            Text("$\(price, specifier: "%.2f")")
                        }
                        if billingCycle == .yearly {
                            HStack {
                                Text("Yearly discount (17%)")
                                    .foregroundColor(.green)
                                Spacer()
                                Text("-$0")
                                    .foregroundColor(.green)
                            }
                        }
                        Divider()
                        HStack {
                            Text("Total today")
                                .fontWeight(.semibold)
                            Spacer()
                            Text("$\(price, specifier: "%.2f")")
                                .fontWeight(.bold)
                        }
                    }
                    .font(.subheadline)
                    .padding()
                    .background(theme.cardBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    
                    // Subscribe Button
                    Button(action: subscribe) {
                        Group {
                            if isProcessing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Subscribe Now")
                                    .fontWeight(.semibold)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(theme.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isProcessing)
                    .padding(.horizontal)
                    
                    Text("By subscribing, you agree to our Terms of Service and Privacy Policy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func subscribe() {
        isProcessing = true
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                isProcessing = false
                dismiss()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SubscriptionView()
}
