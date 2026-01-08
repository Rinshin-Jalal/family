//
//  StoryRequestView.swift
//  StoryRide
//
//  Story Request System - Request missing stories from family
//

import SwiftUI

// MARK: - Story Request Models

struct StoryRequest: Identifiable, Codable {
    let id: UUID
    let question: String
    let description: String?
    let targets: [RequestTarget]
    let status: RequestStatus
    let createdAt: Date
    let expiresAt: Date
    let responsesCount: Int
    
    enum RequestStatus: String, Codable {
        case pending = "pending"
        case partial = "partial"
        case completed = "completed"
        case expired = "expired"
    }
    
    struct RequestTarget: Identifiable, Codable {
        let id: UUID
        let name: String
        let avatarEmoji: String?
        let role: String
        let hasResponded: Bool
        let responseText: String?
    }
}

struct StoryRequestForm {
    let question: String
    let description: String?
    let targetIds: [UUID]
    let relatedStoryId: UUID?
}

struct StoryRequestResponse: Codable {
    let success: Bool
    let request: StoryRequestData
}

struct StoryRequestData: Codable {
    let id: String
    let question: String
    let status: String
}

// MARK: - Story Request View

struct StoryRequestView: View {
    @State private var pendingRequests: [StoryRequest] = []
    @State private var sentRequests: [StoryRequest] = []
    @State private var showCreateRequest = false
    @State private var selectedRequest: StoryRequest?
    @State private var isLoading = false
    
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Create Request Button
                    Button(action: { showCreateRequest = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Request a Story")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(theme.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    
                    // Pending Requests Section
                    if !pendingRequests.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.orange)
                                Text("Waiting for Responses")
                                    .font(.headline)
                                Spacer()
                                Text("\(pendingRequests.count)")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange)
                                    .clipShape(Capsule())
                            }
                            .padding(.horizontal)
                            
                            ForEach(pendingRequests) { request in
                                StoryRequestCard(request: request) {
                                    selectedRequest = request
                                }
                            }
                        }
                    }
                    
                    // Sent Requests History
                    if !sentRequests.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                    .foregroundColor(.blue)
                                Text("Request History")
                                    .font(.headline)
                            }
                            .padding(.horizontal)
                            
                            ForEach(sentRequests) { request in
                                StoryRequestHistoryCard(request: request)
                            }
                        }
                    }
                    
                    // Empty State
                    if pendingRequests.isEmpty && sentRequests.isEmpty {
                        EmptyStoryRequestsView(onCreateRequest: {
                            showCreateRequest = true
                        })
                    }
                }
                .padding(.vertical)
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationTitle("Story Requests")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showCreateRequest) {
                CreateStoryRequestSheet(onRequestCreated: {
                    Task {
                        await loadRequests()
                    }
                })
            }
            .sheet(item: $selectedRequest) { request in
                StoryRequestDetailSheet(request: request)
            }
            .task {
                await loadRequests()
            }
        }
    }
    
    private func loadRequests() async {
        isLoading = true
        // Load from API
        try? await Task.sleep(nanoseconds: 500_000_000)
        isLoading = false
    }
}

// MARK: - Story Request Card

struct StoryRequestCard: View {
    let request: StoryRequest
    let onTap: () -> Void
    
    @Environment(\.theme) var theme
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    statusBadge
                    Spacer()
                    Text("\(request.responsesCount) responses")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
                
                Text(request.question)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.textColor)
                    .multilineTextAlignment(.leading)
                
                if let description = request.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                        .lineLimit(2)
                }
                
                // Target avatars
                HStack(spacing: -8) {
                    ForEach(request.targets.prefix(4)) { target in
                        ZStack {
                            Circle()
                                .fill(target.hasResponded ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: 32, height: 32)
                            Text(target.avatarEmoji ?? "👤")
                                .font(.system(size: 14))
                        }
                        .overlay(
                            Circle()
                                .stroke(target.hasResponded ? Color.green : Color.clear, lineWidth: 2)
                        )
                    }
                    if request.targets.count > 4 {
                        Text("+\(request.targets.count - 4)")
                            .font(.caption)
                            .foregroundColor(theme.secondaryTextColor)
                            .padding(.leading, 12)
                    }
                }
            }
            .padding()
            .background(theme.cardBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(theme.accentColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
    
    private var statusBadge: some View {
        let color: Color
        switch request.status {
        case .pending: color = .orange
        case .partial: color = .yellow
        case .completed: color = .green
        case .expired: color = .gray
        }
        
        return Text(request.status.rawValue.capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color)
            .clipShape(Capsule())
    }
}

// MARK: - Story Request History Card

struct StoryRequestHistoryCard: View {
    let request: StoryRequest
    
    @Environment(\.theme) var theme
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(request.question)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textColor)
                
                HStack(spacing: 8) {
                    Text("\(request.responsesCount) responses")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                    
                    Text("·")
                        .foregroundColor(theme.secondaryTextColor)
                    
                    Text(request.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(theme.secondaryTextColor)
        }
        .padding()
        .background(theme.cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

// MARK: - Empty Story Requests View

struct EmptyStoryRequestsView: View {
    let onCreateRequest: () -> Void
    
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "envelope.badge")
                .font(.system(size: 48))
                .foregroundColor(theme.secondaryTextColor.opacity(0.5))
            
            Text("No Story Requests")
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            Text("Ask family members to share stories about topics you want to learn about.")
                .font(.body)
                .foregroundColor(theme.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: onCreateRequest) {
                Text("Create Request")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(theme.accentColor)
                    .clipShape(Capsule())
            }
        }
        .padding(32)
    }
}

// MARK: - Create Story Request Sheet

struct CreateStoryRequestSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) var theme
    
    @State private var question = ""
    @State private var description = ""
    @State private var selectedTargets: [UUID] = []
    @State private var showTargetSelector = false
    @State private var isSubmitting = false
    
    let onRequestCreated: () -> Void
    
    var canSubmit: Bool {
        !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !selectedTargets.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Question Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What do you want to know?")
                            .font(.headline)
                            .foregroundColor(theme.textColor)
                        
                        Text("Ask a question like \"How did you meet?\" or \"What's your career advice?\"")
                            .font(.caption)
                            .foregroundColor(theme.secondaryTextColor)
                        
                        TextField("Your question...", text: $question, axis: .vertical)
                            .lineLimit(3...6)
                            .padding()
                            .background(theme.cardBackgroundColor)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    
                    // Description (Optional)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add context (optional)")
                            .font(.subheadline)
                            .foregroundColor(theme.textColor)
                        
                        TextEditor(text: $description)
                            .frame(minHeight: 80)
                            .padding(8)
                            .background(theme.cardBackgroundColor)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    
                    // Target Selection
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Ask family members")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(theme.textColor)
                            
                            Spacer()
                            
                            Button(action: { showTargetSelector = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: selectedTargets.isEmpty ? "plus.circle" : "checkmark.circle")
                                    Text(selectedTargets.isEmpty ? "Select" : "\(selectedTargets.count) selected")
                                }
                                .font(.caption)
                                .foregroundColor(theme.accentColor)
                            }
                        }
                        
                        if !selectedTargets.isEmpty {
                            HStack(spacing: 8) {
                                ForEach(0..<min(selectedTargets.count, 5), id: \.self) { index in
                                    Circle()
                                        .fill(Color.blue.opacity(0.3))
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Text("\(index + 1)")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                        )
                                }
                                if selectedTargets.count > 5 {
                                    Text("+\(selectedTargets.count - 5)")
                                        .font(.caption)
                                        .foregroundColor(theme.secondaryTextColor)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(theme.cardBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    
                    Spacer(minLength: 100)
                }
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationTitle("Request a Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") {
                        submitRequest()
                    }
                    .disabled(!canSubmit || isSubmitting)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showTargetSelector) {
                FamilyMemberSelector(selectedIds: $selectedTargets)
            }
        }
    }
    
    private func submitRequest() {
        isSubmitting = true
        Task {
            // API call would go here
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run {
                onRequestCreated()
                dismiss()
            }
        }
    }
}

// MARK: - Family Member Selector

struct FamilyMemberSelector: View {
    @Binding var selectedIds: [UUID]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) var theme
    
    // Mock family members
    let familyMembers = [
        (id: UUID(), name: "Grandma Rose", emoji: "👵", role: "Grandparents"),
        (id: UUID(), name: "Dad", emoji: "👨", role: "Parents"),
        (id: UUID(), name: "Mom", emoji: "👩", role: "Parents"),
        (id: UUID(), name: "Uncle Bob", emoji: "👴", role: "Grandparents")
    ]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(familyMembers, id: \.id) { member in
                    Button(action: {
                        toggleSelection(member.id)
                    }) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.2))
                                    .frame(width: 44, height: 44)
                                Text(member.emoji)
                                    .font(.system(size: 20))
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(member.name)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(theme.textColor)
                                Text(member.role)
                                    .font(.caption)
                                    .foregroundColor(theme.secondaryTextColor)
                            }
                            
                            Spacer()
                            
                            if selectedIds.contains(member.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(theme.accentColor)
                                    .font(.title2)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(theme.secondaryTextColor)
                                    .font(.title2)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Select Family")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func toggleSelection(_ id: UUID) {
        if let index = selectedIds.firstIndex(of: id) {
            selectedIds.remove(at: index)
        } else {
            selectedIds.append(id)
        }
    }
}

// MARK: - Story Request Detail Sheet

struct StoryRequestDetailSheet: View {
    let request: StoryRequest
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) var theme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(request.question)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(theme.textColor)
                        
                        if let description = request.description {
                            Text(description)
                                .font(.body)
                                .foregroundColor(theme.secondaryTextColor)
                        }
                    }
                    
                    Divider()
                    
                    // Responses Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Responses")
                            .font(.headline)
                            .foregroundColor(theme.textColor)
                        
                        ForEach(request.targets) { target in
                            ResponseCard(target: target)
                        }
                    }
                    
                    // Remind Button
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "bell.fill")
                            Text("Send Reminder")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.accentColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(theme.accentColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding()
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationTitle("Request Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Response Card

struct ResponseCard: View {
    let target: StoryRequest.RequestTarget
    
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(target.hasResponded ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Text(target.avatarEmoji ?? "👤")
                        .font(.system(size: 18))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(target.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.textColor)
                    Text(target.role)
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
                
                Spacer()
                
                if target.hasResponded {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Text("Waiting")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            
            if let response = target.responseText, !response.isEmpty {
                Text(response)
                    .font(.body)
                    .foregroundColor(theme.textColor)
                    .padding()
                    .background(theme.cardBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(theme.cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    StoryRequestView()
}
