import SwiftUI
import Combine

enum DeepLinkDestination: Equatable {
    case invite(code: String)
    case story(id: String)
    case quote(id: String)
    case wisdomRequest(id: String)
    case unknown(path: String)
}

@MainActor
final class DeepLinkHandler: ObservableObject {
    static let shared = DeepLinkHandler()

    @Published var pendingDestination: DeepLinkDestination?
    @Published var handledLink: DeepLinkDestination?
    @Published var pendingInviteCode: String?

    private let pendingInviteKey = "pending_invite_code"

    private init() {
        // Restore pending invite code from persistence
        pendingInviteCode = UserDefaults.standard.string(forKey: pendingInviteKey)
    }

    func handle(url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return false
        }

        // Handle both custom scheme (storyrd://) and universal links (https://storyrd.app)
        let host = components.host ?? ""
        let pathComponents = components.path.split(separator: "/").map(String.init)

        let destination: DeepLinkDestination

        // Universal link handling: https://storyrd.app/join/{code}
        if host == "storyrd.app" || host == "www.storyrd.app" {
            if pathComponents.first == "join", let code = pathComponents.dropFirst().first {
                destination = .invite(code: code)
                savePendingInviteCode(code)
            } else if pathComponents.first == "story", let id = pathComponents.dropFirst().first {
                destination = .story(id: id)
            } else if pathComponents.first == "quote", let id = pathComponents.dropFirst().first {
                destination = .quote(id: id)
            } else {
                destination = .unknown(path: url.absoluteString)
            }
        } else {
            // Custom scheme handling: storyrd://invite/{code}
            switch host {
            case "invite":
                let code = components.path.replacingOccurrences(of: "/", with: "")
                destination = .invite(code: code)
                savePendingInviteCode(code)

            case "join":
                let code = components.path.replacingOccurrences(of: "/", with: "")
                destination = .invite(code: code)
                savePendingInviteCode(code)

            case "story":
                let storyId = components.path.replacingOccurrences(of: "/", with: "")
                destination = .story(id: storyId)

            case "quote":
                let quoteId = components.path.replacingOccurrences(of: "/", with: "")
                destination = .quote(id: quoteId)

            case "request":
                let requestId = components.path.replacingOccurrences(of: "/", with: "")
                destination = .wisdomRequest(id: requestId)

            default:
                destination = .unknown(path: url.absoluteString)
            }
        }

        pendingDestination = destination
        return true
    }

    // MARK: - Invite Code Persistence

    /// Save invite code for use after signup/login
    func savePendingInviteCode(_ code: String) {
        pendingInviteCode = code
        UserDefaults.standard.set(code, forKey: pendingInviteKey)
        print("[DeepLink] 📨 Saved pending invite code: \(code)")
    }

    /// Get the pending invite code if one exists
    func getPendingInviteCode() -> String? {
        return pendingInviteCode ?? UserDefaults.standard.string(forKey: pendingInviteKey)
    }

    /// Clear the pending invite code after successful join
    func clearPendingInviteCode() {
        pendingInviteCode = nil
        UserDefaults.standard.removeObject(forKey: pendingInviteKey)
        print("[DeepLink] 🧹 Cleared pending invite code")
    }

    /// Check if there's a pending invite to process
    var hasPendingInvite: Bool {
        return getPendingInviteCode() != nil
    }
    
    func handleUniversalLink(_ userActivity: NSUserActivity) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else {
            return false
        }
        
        return handle(url: url)
    }
    
    func clearPendingLink() {
        pendingDestination = nil
    }
    
    func markAsHandled() {
        if let destination = pendingDestination {
            handledLink = destination
            pendingDestination = nil
        }
    }
}

struct DeepLinkModifier: ViewModifier {
    @ObservedObject private var handler = DeepLinkHandler.shared
    
    let onInvite: (String) -> Void
    let onStory: (String) -> Void
    let onQuote: (String) -> Void
    let onRequest: (String) -> Void
    
    func body(content: Content) -> some View {
        content
            .onChange(of: handler.pendingDestination) { _, newValue in
                if let destination = newValue {
                    handleDestination(destination)
                    handler.markAsHandled()
                }
            }
    }
    
    private func handleDestination(_ destination: DeepLinkDestination) {
        switch destination {
        case .invite(let code):
            onInvite(code)
        case .story(let id):
            onStory(id)
        case .quote(let id):
            onQuote(id)
        case .wisdomRequest(let id):
            onRequest(id)
        case .unknown:
            break
        }
    }
}

extension View {
    func onDeepLink(
        onInvite: @escaping (String) -> Void,
        onStory: @escaping (String) -> Void,
        onQuote: @escaping (String) -> Void,
        onRequest: @escaping (String) -> Void
    ) -> some View {
        modifier(DeepLinkModifier(
            onInvite: onInvite,
            onStory: onStory,
            onQuote: onQuote,
            onRequest: onRequest
        ))
    }
}

struct LinkDestinationData: Codable, Hashable {
    let type: String
    let id: String
    let name: String?
    
    static func from(url: URL) -> LinkDestinationData? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let host = components.host else {
            return nil
        }
        
        let path = components.path.replacingOccurrences(of: "/", with: "")
        
        switch host {
        case "invite":
            return LinkDestinationData(type: "invite", id: path, name: "Family Invite")
        case "story":
            return LinkDestinationData(type: "story", id: path, name: "Family Story")
        case "quote":
            return LinkDestinationData(type: "quote", id: path, name: "Quote Card")
        case "request":
            return LinkDestinationData(type: "request", id: path, name: "Wisdom Request")
        default:
            return nil
        }
    }
}

#Preview("Deep Link Handler") {
    Text("DeepLinkHandler")
        .onDeepLink(
            onInvite: { code in print("Invite: \(code)") },
            onStory: { id in print("Story: \(id)") },
            onQuote: { id in print("Quote: \(id)") },
            onRequest: { id in print("Request: \(id)") }
        )
}
