import SwiftUI

struct CalendarWorkspaceView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 18) {
            topBar

            HSplitView {
                calendarPane
                    .frame(minWidth: 680)

                aiPane
                    .frame(minWidth: 320, maxWidth: 380)
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .overlay {
            if appState.isLoading {
                ProgressView()
                    .controlSize(.large)
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Orbit Calendar")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)

                Text("Decision layer on top of time")
                    .font(.system(size: 18, weight: .medium, design: .serif))
            }

            Spacer()

            HStack(spacing: 10) {
                statPill(title: "Events", value: "\(appState.events.count)")
                statPill(title: "Mode", value: appState.profile?.mode.capitalized ?? "Dev")
            }
        }
        .padding(.horizontal, 6)
    }

    private var calendarPane: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Calendar")
                        .font(.system(size: 30, weight: .semibold, design: .serif))
                    Text("Your next 7 days, with Orbit handling actions on the right.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Refresh") {
                    Task {
                        try? await appState.refreshEvents()
                    }
                }
            }

            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(appState.events) { event in
                        EventCardView(event: event)
                    }
                }
            }
        }
        .padding(28)
    }

    private var aiPane: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ask Orbit")
                .font(.system(size: 22, weight: .semibold, design: .rounded))

            suggestionRow

            TextField(
                "Find 2 hours for deep work tomorrow",
                text: Binding(
                    get: { appState.agentInput },
                    set: { appState.agentInput = $0 }
                ),
                axis: .vertical
            )
                .textFieldStyle(.roundedBorder)

            Button("Run Command") {
                Task {
                    await appState.runAgent()
                }
            }
            .buttonStyle(.borderedProminent)

            Divider()

            if let response = appState.latestAgentResponse {
                Text(response.message)
                    .font(.body)
                if let slots = response.data.candidateSlots, !slots.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(slots) { slot in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(slot.start)
                                Text(slot.end)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
            } else {
                Text("Orbit responses appear here as operational summaries, not a chat log.")
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(24)
        .background(Color.white.opacity(0.32))
    }

    private var suggestionRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                suggestionChip("What does my day look like?")
                suggestionChip("When am I free for 2 hours tomorrow?")
                suggestionChip("Block deep work tomorrow")
                suggestionChip("Open booking settings")
            }
        }
    }

    private func suggestionChip(_ text: String) -> some View {
        Button(text) {
            appState.agentInput = text
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.55), in: Capsule())
    }

    private func statPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

}

struct EventCardView: View {
    let event: CalendarEvent

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.startsAt.formatted(.dateTime.hour().minute()))
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                Text(event.startsAt.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 88, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                Text(event.title ?? "Untitled")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))

                Text("\(event.startsAt.formatted(date: .omitted, time: .shortened)) - \(event.endsAt.formatted(date: .omitted, time: .shortened))")
                    .foregroundStyle(.secondary)

                if let description = event.description, !description.isEmpty {
                    Text(description)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
