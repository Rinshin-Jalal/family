//
//  NavigationCoordinator.swift
//  familyplus
//
//  Coordinates cross-tab navigation and pending modal actions
//

import SwiftUI
import Combine

// MARK: - Main Tab

enum MainTab: String, CaseIterable {
    case hub
    case family
    case settings
    
    var icon: String {
        switch self {
        case .hub: return "house.fill"
        case .family: return "person.2.fill"
        case .settings: return "person.fill"
        }
    }
}

// MARK: - Family Tab Action

/// Actions that can be triggered on the Family tab from other parts of the app
enum FamilyTabAction: Equatable {
    case showAddElder
    case showManageMembers
    case showGovernance
    case none
}

// MARK: - Navigation Coordinator

/// Shared coordinator for cross-tab navigation and pending actions
@MainActor
class NavigationCoordinator: ObservableObject {
    static let shared = NavigationCoordinator()

    /// Pending action to execute when Family tab becomes active
    @Published var pendingFamilyAction: FamilyTabAction = .none

    /// Current selected tab - can be bound from MainTabView
    @Published var selectedTab: MainTab = .hub

    private init() {}

    /// Navigate to Family tab and trigger a specific action
    /// - Parameter action: The action to trigger on the Family tab
    func navigateToFamily(action: FamilyTabAction) {
        pendingFamilyAction = action
        selectedTab = .family
    }

    /// Clear pending action after it's been handled
    func clearPendingAction() {
        pendingFamilyAction = .none
    }
}

// MARK: - Preview Helper

extension NavigationCoordinator {
    static var preview: NavigationCoordinator {
        NavigationCoordinator.shared
    }
}
