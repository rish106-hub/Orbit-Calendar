import SwiftUI

struct CalendarWorkspaceView: View {
    @Environment(AppState.self) private var appState

    private let timelineStartHour = 7
    private let timelineEndHour = 22
    private let hourRowHeight: CGFloat = 72
    private let dayColumnWidth: CGFloat = 180

    var body: some View {
        VStack(spacing: 18) {
            topBar

            HSplitView {
                calendarPane
                    .frame(minWidth: 760)

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

    private var visibleDays: [Date] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
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
                statPill(title: "Range", value: "7 Days")
                statPill(title: "Provider", value: appState.profile?.calendarProvider.capitalized ?? "Local")
            }
        }
        .padding(.horizontal, 6)
    }

    private var calendarPane: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Weekly View")
                        .font(.system(size: 30, weight: .semibold, design: .serif))
                        .foregroundStyle(OrbitTheme.textPrimary)
                    Text("A 7-day focus window with a real time rail and event placement.")
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

            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {
                    calendarHeader
                    timelineGrid
                }
            }

            scheduleSummary
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

    private var calendarHeader: some View {
        HStack(spacing: 12) {
            Text("Time")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .textCase(.uppercase)
                .foregroundStyle(OrbitTheme.textMuted)
                .frame(width: 72, alignment: .leading)

            HStack(spacing: 12) {
                ForEach(visibleDays, id: \.self) { day in
                    let events = events(for: day)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(day.formatted(.dateTime.weekday(.abbreviated)))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .textCase(.uppercase)
                            .foregroundStyle(OrbitTheme.textMuted)
                        Text(day.formatted(.dateTime.day()))
                            .font(.system(size: 26, weight: .semibold, design: .serif))
                            .foregroundStyle(OrbitTheme.textPrimary)
                        Text(events.isEmpty ? "Open" : "\(events.count) event\(events.count == 1 ? "" : "s")")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(OrbitTheme.textSecondary)
                    }
                    .padding(16)
                    .frame(width: dayColumnWidth, alignment: .leading)
                    .background(OrbitTheme.panelSoft, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
            }
        }
        .padding(.bottom, 14)
    }

    private var timelineGrid: some View {
        HStack(alignment: .top, spacing: 12) {
            timeRail

            HStack(alignment: .top, spacing: 12) {
                ForEach(visibleDays, id: \.self) { day in
                    DayTimelineColumn(
                        day: day,
                        events: events(for: day),
                        startHour: timelineStartHour,
                        endHour: timelineEndHour,
                        hourRowHeight: hourRowHeight,
                        width: dayColumnWidth
                    )
                }
            }
        }
    }

    private var timeRail: some View {
        VStack(spacing: 0) {
            ForEach(timelineStartHour..<timelineEndHour, id: \.self) { hour in
                VStack(alignment: .leading, spacing: 0) {
                    Text(hourLabel(hour))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(OrbitTheme.textMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 2)
                    Spacer()
                }
                .frame(width: 72, height: hourRowHeight, alignment: .topLeading)
            }
        }
    }

    private var scheduleSummary: some View {
        HStack(spacing: 14) {
            summaryCard(
                title: "Busiest Day",
                value: busiestDayLabel,
                caption: "Highest event count in the current 7-day window."
            )
            summaryCard(
                title: "Longest Block",
                value: longestEventLabel,
                caption: "Largest scheduled event currently visible."
            )
            summaryCard(
                title: "Open Days",
                value: "\(visibleDays.filter { events(for: $0).isEmpty }.count)",
                caption: "Days with no scheduled events in this view."
            )
        }
    }

    private var busiestDayLabel: String {
        guard let day = visibleDays.max(by: { events(for: $0).count < events(for: $1).count }) else {
            return "None"
        }
        let count = events(for: day).count
        return count == 0 ? "Clear Week" : "\(day.formatted(.dateTime.weekday(.wide))) · \(count)"
    }

    private var longestEventLabel: String {
        guard let event = appState.events.max(by: { $0.endsAt.timeIntervalSince($0.startsAt) < $1.endsAt.timeIntervalSince($1.startsAt) }) else {
            return "No Events"
        }
        let duration = Int(event.endsAt.timeIntervalSince(event.startsAt) / 60)
        return "\(duration)m · \(event.title ?? "Untitled")"
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
            .orbitInlineField()

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

    private func summaryCard(title: String, value: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .textCase(.uppercase)
                .foregroundStyle(OrbitTheme.textMuted)
            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundStyle(OrbitTheme.textPrimary)
            Text(caption)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(OrbitTheme.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OrbitTheme.panelSoft, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func events(for day: Date) -> [CalendarEvent] {
        let calendar = Calendar.current
        return appState.events
            .filter { calendar.isDate($0.startsAt, inSameDayAs: day) }
            .sorted(by: { $0.startsAt < $1.startsAt })
    }

    private func hourLabel(_ hour: Int) -> String {
        let normalized = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        let suffix = hour >= 12 ? "PM" : "AM"
        return "\(normalized) \(suffix)"
    }
}

private struct DayTimelineColumn: View {
    let day: Date
    let events: [CalendarEvent]
    let startHour: Int
    let endHour: Int
    let hourRowHeight: CGFloat
    let width: CGFloat

    private var totalHeight: CGFloat {
        CGFloat(endHour - startHour) * hourRowHeight
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                ForEach(startHour..<endHour, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.white.opacity(0.03))
                        .frame(height: hourRowHeight)
                        .overlay(alignment: .top) {
                            Rectangle()
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 1)
                        }
                }
            }

            ForEach(events) { event in
                TimelineEventBlock(
                    event: event,
                    startHour: startHour,
                    endHour: endHour,
                    hourRowHeight: hourRowHeight
                )
                .padding(.horizontal, 8)
            }
        }
        .frame(width: width, height: totalHeight, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.08),
                    Color.white.opacity(0.04),
                ],
                startPoint: .top,
                endPoint: .bottom
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct TimelineEventBlock: View {
    let event: CalendarEvent
    let startHour: Int
    let endHour: Int
    let hourRowHeight: CGFloat

    private var calendar: Calendar { Calendar.current }

    private var startOffset: CGFloat {
        let hour = calendar.component(.hour, from: event.startsAt)
        let minute = calendar.component(.minute, from: event.startsAt)
        let rawHours = CGFloat(hour - startHour) + CGFloat(minute) / 60
        return max(0, rawHours * hourRowHeight)
    }

    private var blockHeight: CGFloat {
        let minutes = max(30, event.endsAt.timeIntervalSince(event.startsAt) / 60)
        let visibleHeight = CGFloat(minutes / 60) * hourRowHeight
        return min(max(visibleHeight, 52), CGFloat(endHour - startHour) * hourRowHeight - startOffset)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(event.title ?? "Untitled")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(OrbitTheme.textPrimary)
                .lineLimit(2)

            Text("\(event.startsAt.formatted(date: .omitted, time: .shortened)) - \(event.endsAt.formatted(date: .omitted, time: .shortened))")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(OrbitTheme.textSecondary)
                .lineLimit(1)

            if let location = event.location, !location.isEmpty, blockHeight > 84 {
                Text(location)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(OrbitTheme.textMuted)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: blockHeight, maxHeight: blockHeight, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [
                    OrbitTheme.accentStrong.opacity(0.82),
                    OrbitTheme.glowA.opacity(0.55),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: OrbitTheme.shadow.opacity(0.65), radius: 16, x: 0, y: 10)
        .offset(y: startOffset)
    }
}
