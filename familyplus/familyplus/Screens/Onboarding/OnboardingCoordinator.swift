//
//  OnboardingCoordinator.swift
//  StoryRd
//
//  Navigation coordinator for the complete onboarding flow
//

import SwiftUI
import Combine

// MARK: - Onboarding Step

enum OnboardingStep: Int, CaseIterable, Identifiable {
    case welcome = 0
    case hookQuestion = 1
    case hookAudio = 2
    case hookFamilyChat = 3
    case hookSearch = 4
    case hookWrittenStory = 5
    case hookPhoto = 6
    case hookVoiceClone = 7
    case hookKids = 8
    case hookPodcast = 9
    case hookQuote = 10
    
    case pitchProblem = 11
    case pitchOpportunity = 12
    case pitchSolution = 13
    case pitchHowItWorks1 = 14
    case pitchHowItWorksCollection = 15
    case pitchHowItWorks2 = 16
    case pitchHowItWorks3 = 17
    case pitchSocialProof1 = 18
    case pitchSocialProof2 = 19
    case pitchOffer = 20
    
    case familyCreateOrJoin = 21
    case familyName = 22
    case familyRole = 23
    case familyYourName = 24
    case familyInviteElders = 25
    case familyInviteParents = 26
    case familyInviteSiblings = 27
    case familyReady = 28
    
    case howToCollect = 29
    case recordQuestion = 30
    case recordTips = 31
    case recordCall = 32
    case recordComplete = 33
    case recordProcessing = 34
    case recordReveal = 35
    case recordTags = 36
    case recordContributions = 37
    case recordShareQuote = 38
    case recordKids = 39
    case recordVoiceCloneResult = 40
    case recordUpsell = 41
    
    var id: Int { rawValue }
    
    var isPitch: Bool {
        rawValue >= 11 && rawValue <= 20
    }
    
    var isFamilySetup: Bool {
        rawValue >= 21 && rawValue <= 28
    }
    
    var isFirstStory: Bool {
        rawValue >= 29
    }
}

// MARK: - Onboarding State

struct OnboardingState {
    var isCompleted: Bool = false
    var familyId: String?
    var familyName: String?
    var userRole: String = ""
    var userName: String = ""
    var invitedMembers: [InvitedMember] = []
}

struct InvitedMember: Identifiable {
    let id: UUID
    let name: String
    let phone: String?
    let email: String?
    let role: String
}

// MARK: - Recording State

struct RecordingState {
    var isRecording: Bool = false
    var duration: TimeInterval = 0
    var audioURL: URL?
    var question: OnboardingPrompt?
}

// MARK: - Prompt Data

struct OnboardingPrompt: Identifiable {
    let id: UUID
    let text: String
    var category: String?
    var isCustom: Bool = false
    
    init(id: UUID = UUID(), text: String, category: String? = nil, isCustom: Bool = false) {
        self.id = id
        self.text = text
        self.category = category
        self.isCustom = isCustom
    }
}

// MARK: - Family Relationship

enum FamilyRelationship: String, CaseIterable {
    case spouse = "spouse"
    case parent = "parent"
    case grandparent = "grandparent"
    case child = "child"
    case sibling = "sibling"
    case extended = "extended"
}

struct FamilyMemberInvite: Identifiable {
    let id: UUID = UUID()
    let name: String
    let phone: String?
    let email: String?
    let relationship: FamilyRelationship
}

// MARK: - OnboardingCoordinator

final class OnboardingCoordinator: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var onboardingState = OnboardingState()
    @Published var recordingState = RecordingState()
    @Published var showSubscription: Bool = false
    @Published var isLoading: Bool = false
    
    private var navigationTask: Task<Void, Never>?
    
    // MARK: - Step Navigation
    
    func goToNextStep() {
        let nextStepRawValue = currentStep.rawValue + 1
        guard let nextStep = OnboardingStep(rawValue: nextStepRawValue) else {
            completeOnboarding()
            return
        }
        currentStep = nextStep
    }
    
    func goToStep(_ step: OnboardingStep) {
        currentStep = step
    }
    
    func skipPitch() {
        currentStep = .familyCreateOrJoin
    }
    
    func skipToRecording() {
        currentStep = .recordQuestion
    }
    
    func completeOnboarding() {
        onboardingState.isCompleted = true
    }
    
    // MARK: - Family Actions
    
    func createFamily(name: String) async {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate API call
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        onboardingState.familyId = UUID().uuidString
        onboardingState.familyName = name
        goToStep(.familyRole)
    }
    
    func joinFamily(code: String) async {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate API call
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        onboardingState.familyId = UUID().uuidString
        onboardingState.familyName = "Family"
        goToStep(.familyReady)
    }
    
    func setUserRole(_ role: String, name: String) {
        onboardingState.userRole = role
        onboardingState.userName = name
    }
    
    func inviteMember(_ member: FamilyMemberInvite) {
        let invited = InvitedMember(
            id: UUID(),
            name: member.name,
            phone: member.phone,
            email: member.email,
            role: member.relationship.rawValue
        )
        onboardingState.invitedMembers.append(invited)
    }
    
    // MARK: - Recording Actions
    
    func startRecording() {
        recordingState.isRecording = true
        recordingState.duration = 0
        goToStep(.recordCall)
    }
    
    func stopRecording() {
        recordingState.isRecording = false
        goToStep(.recordComplete)
    }
    
    func selectQuestion(_ question: OnboardingPrompt) {
        recordingState.question = question
        goToStep(.recordTips)
    }
    
    func uploadExistingAudio() async {
        recordingState.audioURL = URL(string: "file://sample.m4a")
        goToStep(.recordProcessing)
    }
    
    // MARK: - Subscription
    
    func startFreeTrial() {
        showSubscription = false
        goToStep(.familyCreateOrJoin)
    }
    
    func continueFree() {
        showSubscription = false
        goToStep(.familyCreateOrJoin)
    }
    
    // MARK: - Progress
    
    var progress: Double {
        Double(currentStep.rawValue) / Double(OnboardingStep.allCases.count - 1)
    }
    
    var totalSteps: Int {
        OnboardingStep.allCases.count
    }
    
    var currentStepNumber: Int {
        currentStep.rawValue + 1
    }
    
    @ViewBuilder
    var currentView: some View {
        switch currentStep {
        case .welcome:
            WelcomeScreenView(coordinator: self)
        case .hookQuestion:
            HookQuestionScreenView(coordinator: self)
        case .hookAudio:
            HookAudioScreenView(coordinator: self)
        case .hookFamilyChat:
            HookFamilyChatScreenView(coordinator: self)
        case .hookSearch:
            HookSearchScreenView(coordinator: self)
        case .hookWrittenStory:
            HookWrittenStoryScreenView(coordinator: self)
        case .hookPhoto:
            HookPhotoScreenView(coordinator: self)
        case .hookVoiceClone:
            HookVoiceCloneScreenView(coordinator: self)
        case .hookKids:
            HookKidsScreenView(coordinator: self)
        case .hookPodcast:
            HookPodcastScreenView(coordinator: self)
        case .hookQuote:
            HookQuoteScreenView(coordinator: self)
        case .pitchProblem:
            PitchProblemScreenView(coordinator: self)
        case .pitchOpportunity:
            PitchOpportunityScreenView(coordinator: self)
        case .pitchSolution:
            PitchSolutionScreenView(coordinator: self)
        case .pitchHowItWorks1:
            PitchHowItWorks1ScreenView(coordinator: self)
        case .pitchHowItWorksCollection:
            PitchHowItWorksCollectionScreenView(coordinator: self)
        case .pitchHowItWorks2:
            PitchHowItWorks2ScreenView(coordinator: self)
        case .pitchHowItWorks3:
            PitchHowItWorks3ScreenView(coordinator: self)
        case .pitchSocialProof1:
            PitchSocialProof1ScreenView(coordinator: self)
        case .pitchSocialProof2:
            PitchSocialProof2ScreenView(coordinator: self)
        case .pitchOffer:
            PitchOfferScreenView(coordinator: self)
        case .familyCreateOrJoin:
            FamilyCreateOrJoinScreenView(coordinator: self)
        case .familyName:
            FamilyNameScreenView(coordinator: self)
        case .familyRole:
            FamilyRoleScreenView(coordinator: self)
        case .familyYourName:
            FamilyYourNameScreenView(coordinator: self)
        case .familyInviteElders:
            FamilyInviteEldersScreenView(coordinator: self)
        case .familyInviteParents:
            FamilyInviteParentsScreenView(coordinator: self)
        case .familyInviteSiblings:
            FamilyInviteSiblingsScreenView(coordinator: self)
        case .familyReady:
            FamilyReadyScreenView(coordinator: self)
        case .howToCollect:
            HowToCollectScreenView(coordinator: self)
        case .recordQuestion:
            RecordQuestionScreenView(coordinator: self)
        case .recordTips:
            RecordTipsScreenView(coordinator: self)
        case .recordCall:
            RecordCallScreenView(coordinator: self)
        case .recordComplete:
            RecordCompleteScreenView(coordinator: self)
        case .recordProcessing:
            RecordProcessingScreenView(coordinator: self)
        case .recordReveal:
            RecordRevealScreenView(coordinator: self)
        case .recordTags:
            RecordTagsScreenView(coordinator: self)
        case .recordContributions:
            RecordContributionsScreenView(coordinator: self)
        case .recordShareQuote:
            RecordShareQuoteScreenView(coordinator: self)
        case .recordKids:
            RecordKidsScreenView(coordinator: self)
        case .recordVoiceCloneResult:
            RecordVoiceCloneResultScreenView(coordinator: self)
        case .recordUpsell:
            RecordUpsellScreenView(coordinator: self)
        }
    }
    
    static var preview: OnboardingCoordinator {
        OnboardingCoordinator()
    }
}
