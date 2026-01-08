import SwiftUI

struct PollCard: View {
    let poll: PollData
    let onVote: (PollOption) -> Void
    let onViewResults: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(poll.question)
                    .font(theme.headlineFont)
                    .foregroundColor(theme.textColor)

                if let description = poll.description, !description.isEmpty {
                    Text(description)
                        .font(theme.bodyFont)
                        .foregroundColor(theme.secondaryTextColor)
                }

                HStack {
                    Label(poll.pollType, systemImage: "chart.bar.fill")
                        .font(.caption)
                        .foregroundColor(.blue)

                    Spacer()

                    Text("\(poll.totalVotes) votes")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
            }

            if poll.hasVoted {
                PollResultsView(poll: poll, onViewDetails: onViewResults)
            } else {
                PollOptionsView(
                    options: poll.options,
                    onVote: onVote
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: theme.cardRadius * 1.5)
                .fill(.ultraThinMaterial)
        )
    }
}

struct PollOptionsView: View {
    let options: [PollOption]
    let onVote: (PollOption) -> Void

    var body: some View {
        VStack(spacing: 12) {
            ForEach(options, id: \.id) { option in
                PollOptionButton(option: option) {
                    onVote(option)
                }
            }
        }
    }
}

struct PollOptionButton: View {
    let option: PollOption
    let onTap: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(option.label)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(.blue)
                    .clipShape(Circle())

                Text(option.optionText)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.textColor)

                Spacer()

                if let generation = option.generation {
                    Text(generation)
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.blue.opacity(0.1))
                        )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: theme.cardRadius)
                    .fill(.ultraThinMaterial)
            )
        }
        .buttonStyle(.plain)
    }
}

struct PollResultsView: View {
    let poll: PollData
    let onViewDetails: () -> Void

    @Environment(\.theme) private var theme

    var totalVotes: Int {
        poll.options.reduce(0) { $0 + $1.voteCount }
    }

    var body: some View {
        VStack(spacing: 12) {
            ForEach(poll.options, id: \.id) { option in
                PollResultBar(
                    option: option,
                    totalVotes: totalVotes
                )
            }

            Button(action: onViewDetails) {
                Text("View Details")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
            }
            .padding(.top, 8)
        }
    }
}

struct PollResultBar: View {
    let option: PollOption
    let totalVotes: Int

    @Environment(\.theme) private var theme

    var percentage: Double {
        guard totalVotes > 0 else { return 0 }
        return Double(option.voteCount) / Double(totalVotes) * 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(option.label)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(barColor)
                    .clipShape(Circle())

                Text(option.optionText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.textColor)

                Spacer()

                Text("\(Int(percentage))%")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.textColor)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.blue.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: geometry.size.width * CGFloat(percentage / 100), height: 8)
                }
            }
            .frame(height: 8)
        }
    }

    private var barColor: Color {
        switch option.generation?.lowercased() {
        case "grandparents", "elder": return .orange
        case "parents", "organizer": return .blue
        case "kids", "child": return .green
        default: return .blue
        }
    }
}

struct PollData: Identifiable, Codable {
    let id: String
    let question: String
    let description: String?
    let pollType: String
    let endsAt: String
    let options: [PollOption]
    let hasVoted: Bool
    let totalVotes: Int

    enum CodingKeys: String, CodingKey {
        case id, question, description
        case pollType = "poll_type"
        case endsAt = "ends_at"
        case options
        case hasVoted = "has_voted"
        case totalVotes = "total_votes"
    }
}

struct PollOption: Identifiable, Codable {
    let id: String
    let optionText: String
    let label: String
    let generation: String?
    let voteCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case optionText = "text"
        case label, generation
        case voteCount = "vote_count"
    }
}

struct PollListView: View {
    @State private var polls: [PollData] = []
    @State private var isLoading = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading polls...")
            } else if polls.isEmpty {
                EmptyPollsView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(polls) { poll in
                            PollCard(
                                poll: poll,
                                onVote: { option in
                                    vote(pollId: poll.id, optionId: option.id)
                                },
                                onViewResults: {}
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .task {
            await loadPolls()
        }
    }

    private func loadPolls() async {
        isLoading = true
        // TODO: Call API to load polls
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isLoading = false
    }

    private func vote(pollId: String, optionId: String) {
        // TODO: Call API to vote
    }
}

struct EmptyPollsView: View {
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 48))
                .foregroundColor(theme.secondaryTextColor)

            Text("No Active Polls")
                .font(theme.headlineFont)
                .foregroundColor(theme.textColor)

            Text("Family polls will appear here")
                .font(theme.bodyFont)
                .foregroundColor(theme.secondaryTextColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
