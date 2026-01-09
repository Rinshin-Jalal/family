//
//  SimpleOnboardingCoordinator.swift
//  StoryRide
//
//  Simplified onboarding - 3 steps max
//  Value extraction focus: Start capturing immediately
//

import SwiftUI
import Combine
import Auth

// MARK: - Simple Onboarding Steps

enum SimpleOnboardingStep: Int, CaseIterable, Identifiable {
    case welcome = 0
    case whatToPreserve = 1
    case whoFor = 2
    case startCapturing = 3

    var id: Int { rawValue }
}

// MARK: - Simple Onboarding State

struct SimpleOnboardingState {
    var isCompleted: Bool = false
    var preserveTypes: Set<PreserveType> = []
    var captureTarget: CaptureTarget = .myself
    var userName: String = ""
}

// MARK: - Preserve Types

enum PreserveType: String, CaseIterable {
    case stories = "Stories"
    case photos = "Photos"
    case documents = "Documents"
    case audio = "Audio"

    var icon: String {
        switch self {
        case .stories: return "book.fill"
        case .photos: return "photo.fill"
        case .documents: return "doc.fill"
        case .audio: return "waveform.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .stories: return .purple
        case .photos: return .blue
        case .documents: return .orange
        case .audio: return .green
        }
    }

    var description: String {
        switch self {
        case .stories: return "Childhood memories, family history"
        case .photos: return "Old photos, letters, albums"
        case .documents: return "Recipes, certificates, records"
        case .audio: return "Voice recordings, conversations"
        }
    }
}

// MARK: - Capture Target

enum CaptureTarget: String, CaseIterable {
    case myself = "Myself"
    case familyMember = "Family Member"
    case archive = "Archive"

    var icon: String {
        switch self {
        case .myself: return "person.fill"
        case .familyMember: return "person.2.fill"
        case .archive: return "archivebox.fill"
        }
    }

    var description: String {
        switch self {
        case .myself: return "Preserve my own memories"
        case .familyMember: return "Capture stories from loved ones"
        case .archive: return "Build a family archive"
        }
    }
}

// MARK: - Simple Onboarding Coordinator

final class SimpleOnboardingCoordinator: ObservableObject {
    @Published var currentStep: SimpleOnboardingStep = .welcome
    @Published var onboardingState = SimpleOnboardingState()
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var showError: Bool = false

    // MARK: - Navigation

    func goToNextStep() {
        guard let nextStep = SimpleOnboardingStep(rawValue: currentStep.rawValue + 1) else {
            completeOnboarding()
            return
        }
        currentStep = nextStep
    }

    func goToStep(_ step: SimpleOnboardingStep) {
        currentStep = step
    }

    func completeOnboarding() {
        // Create account and WAIT for it before marking complete
        Task { @MainActor in
            await createAccountInBackground()

            // Only mark completed if auth succeeded (no error)
            if !showError && AuthService.shared.isAuthenticated {
                onboardingState.isCompleted = true
            }
        }
    }

    // MARK: - Selection Actions

    func togglePreserveType(_ type: PreserveType) {
        if onboardingState.preserveTypes.contains(type) {
            onboardingState.preserveTypes.remove(type)
        } else {
            onboardingState.preserveTypes.insert(type)
        }
    }

    func setCaptureTarget(_ target: CaptureTarget) {
        onboardingState.captureTarget = target
    }

    func setUserName(_ name: String) {
        onboardingState.userName = name
    }

    // MARK: - Background Account Creation

    func createAccountInBackground() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // 1. Generate anonymous credentials for frictionless signup
            let uuid = UUID().uuidString.prefix(8)
            let email = "anon-\(uuid)@familyplus.local"
            let password = UUID().uuidString

            // 2. Create Supabase account
            let session = try await SupabaseService.shared.signUp(
                email: String(email),
                password: password
            )

            // 3. Store auth token in AuthService
            AuthService.shared.setToken(session.accessToken)

            // 4. Create family with default name
            let familyName = onboardingState.userName.isEmpty
                ? "My Family"
                : "\(onboardingState.userName)'s Family"
            let _ = try await APIService.shared.createFamily(name: familyName)

            // 5. Save onboarding preferences locally
            savePreferencesLocally()

            print("✅ Account created successfully")
            print("   User ID: \(session.user.id)")
            print("   Email: \(email)")
            print("   Preserve types: \(onboardingState.preserveTypes)")
            print("   Target: \(onboardingState.captureTarget)")

        } catch {
            print("❌ Account creation failed: \(error)")
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func savePreferencesLocally() {
        // Store preferences in UserDefaults for later sync
        let preserveTypes = onboardingState.preserveTypes.map { $0.rawValue }
        UserDefaults.standard.set(preserveTypes, forKey: "onboarding_preserve_types")
        UserDefaults.standard.set(onboardingState.captureTarget.rawValue, forKey: "onboarding_capture_target")
    }

    // MARK: - Progress

    var progress: Double {
        Double(currentStep.rawValue) / Double(SimpleOnboardingStep.allCases.count - 1)
    }

    var totalSteps: Int {
        SimpleOnboardingStep.allCases.count
    }

    var currentStepNumber: Int {
        currentStep.rawValue + 1
    }

    // MARK: - Current View

    @ViewBuilder
    var currentView: some View {
        switch currentStep {
        case .welcome:
            SimpleWelcomeView(coordinator: self)
        case .whatToPreserve:
            SimpleWhatToPreserveView(coordinator: self)
        case .whoFor:
            SimpleWhoForView(coordinator: self)
        case .startCapturing:
            SimpleStartCapturingView(coordinator: self)
        }
    }

    static var preview: SimpleOnboardingCoordinator {
        SimpleOnboardingCoordinator()
    }
}
