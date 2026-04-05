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
            .orbitGlassCard(radius: 30, fill: OrbitTheme.panelFill)
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
                    .foregroundStyle(OrbitTheme.textSecondary)

                Text("Decision layer on top of time")
                    .font(.system(size: 18, weight: .medium, design: .serif))
                    .foregroundStyle(OrbitTheme.textPrimary)
            }

            Spacer()

            HStack(spacing: 10) {
                statPill(title: "Events", value: "\(appState.events.count)")
                statPill(title: "Provider", value: appState.profile?.calendarProvider.capitalized ?? "Local")
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
                        .foregroundStyle(OrbitTheme.textPrimary)
                    Text("Your next 7 days, with Orbit handling actions on the right.")
                        .foregroundStyle(OrbitTheme.textSecondary)
                }
                Spacer()
                Button("Refresh") {
                    Task {
                        try? await appState.refreshEvents()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(OrbitTheme.accentStrong)
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
        .background(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.06),
                    Color.white.opacity(0.02),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var aiPane: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ask Orbit")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(OrbitTheme.textPrimary)

            suggestionRow

            TextField(
                "Find 2 hours for deep work tomorrow",
                text: Binding(
                    get: { appState.agentInput },
                    set: { appState.agentInput = $0 }
                ),
                axis: .vertical
            )
            .textFieldStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .foregroundStyle(OrbitTheme.textPrimary)

            Button("Run Command") {
                Task {
                    await appState.runAgent()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(OrbitTheme.accentStrong)

            Rectangle()
                .fill(OrbitTheme.divider)
                .frame(height: 1)

            if let response = appState.latestAgentResponse {
                Text(response.message)
                    .font(.body)
                    .foregroundStyle(OrbitTheme.textPrimary)
                if let slots = response.data.candidateSlots, !slots.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(slots) { slot in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(slot.start)
                                    .foregroundStyle(OrbitTheme.textPrimary)
                                Text(slot.end)
                                    .foregroundStyle(OrbitTheme.textSecondary)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            )
                        }
                    }
                }
            } else {
                Text("Orbit responses appear here as operational summaries, not a chat log.")
                    .foregroundStyle(OrbitTheme.textSecondary)
            }

            Spacer()
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.08),
                    Color.white.opacity(0.04),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
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
        .foregroundStyle(OrbitTheme.textPrimary)
        .background(Color.white.opacity(0.10), in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func statPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(OrbitTheme.textMuted)
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(OrbitTheme.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

}

struct EventCardView: View {
    let event: CalendarEvent

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.startsAt.formatted(.dateTime.hour().minute()))
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(OrbitTheme.eventTint)
                Text(event.startsAt.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(OrbitTheme.textMuted)
            }
            .frame(width: 88, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                Text(event.title ?? "Untitled")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(OrbitTheme.textPrimary)

                Text("\(event.startsAt.formatted(date: .omitted, time: .shortened)) - \(event.endsAt.formatted(date: .omitted, time: .shortened))")
                    .foregroundStyle(OrbitTheme.textSecondary)

                if let description = event.description, !description.isEmpty {
                    Text(description)
                        .font(.callout)
                        .foregroundStyle(OrbitTheme.textSecondary)
                }
            }
            Spacer()
            Circle()
                .fill(
                    LinearGradient(
                        colors: [OrbitTheme.accent, OrbitTheme.glowB],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 10, height: 10)
                .padding(.top, 8)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.12),
                    Color.white.opacity(0.07),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }
}
