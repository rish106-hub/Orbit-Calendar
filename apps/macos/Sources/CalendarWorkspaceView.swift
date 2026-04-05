import SwiftUI

struct CalendarWorkspaceView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HSplitView {
            calendarPane
                .frame(minWidth: 680)

            aiPane
                .frame(minWidth: 320, maxWidth: 380)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            if appState.isLoading {
                ProgressView()
                    .controlSize(.large)
            }
        }
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

            TextField("Find 2 hours for deep work tomorrow", text: $appState.agentInput, axis: .vertical)
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
        VStack(alignment: .leading, spacing: 8) {
            suggestionButton("What does my day look like?")
            suggestionButton("When am I free for 2 hours tomorrow?")
            suggestionButton("Block deep work tomorrow")
            suggestionButton("Open booking settings")
        }
    }

    private func suggestionButton(_ text: String) -> some View {
        Button(text) {
            appState.agentInput = text
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
    }
}

struct EventCardView: View {
    let event: CalendarEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(event.title ?? "Untitled")
                .font(.system(size: 20, weight: .semibold, design: .rounded))

            Text("\(event.startsAt.formatted(date: .abbreviated, time: .shortened)) - \(event.endsAt.formatted(date: .omitted, time: .shortened))")
                .foregroundStyle(.secondary)

            if let description = event.description, !description.isEmpty {
                Text(description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
