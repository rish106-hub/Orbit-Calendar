import SwiftUI

struct BookingSettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Booking Link")
                        .font(.system(size: 30, weight: .semibold, design: .serif))
                        .foregroundStyle(OrbitTheme.textPrimary)
                    Text("One public link for the MVP, with buffers and notice controls.")
                        .foregroundStyle(OrbitTheme.textSecondary)
                }
                Spacer()
                if let bookingPage = appState.bookingPage {
                    Text("orbit.app/\(bookingPage.slug)")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .foregroundStyle(OrbitTheme.textPrimary)
                        .background(Color.white.opacity(0.12), in: Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
                }
            }

            if let bookingPage = appState.bookingPage {
                HStack(alignment: .top, spacing: 20) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Booking Rules")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(OrbitTheme.textPrimary)
                        Text("Tune the public link without leaving the desktop workspace.")
                            .foregroundStyle(OrbitTheme.textSecondary)

                        Rectangle()
                            .fill(OrbitTheme.divider)
                            .frame(height: 1)

                        VStack(alignment: .leading, spacing: 8) {
                            fieldLabel("Slug")
                            TextField("Slug", text: binding(\.slug))
                                .orbitInlineField()
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            fieldLabel("Title")
                            TextField("Title", text: binding(\.title))
                                .orbitInlineField()
                        }

                        Toggle(isOn: binding(\.active)) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Booking page active")
                                    .foregroundStyle(OrbitTheme.textPrimary)
                                Text("Turn the public page on or off without deleting settings.")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundStyle(OrbitTheme.textSecondary)
                            }
                        }
                        .toggleStyle(.switch)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(OrbitTheme.panelSoft, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        )

                        valueStepper(
                            title: "Meeting length",
                            valueText: "\(bookingPage.defaultDurationMinutes) min",
                            binding: binding(\.defaultDurationMinutes),
                            range: 15...180,
                            step: 15
                        )
                        valueStepper(
                            title: "Buffer before",
                            valueText: "\(bookingPage.bufferBeforeMinutes) min",
                            binding: binding(\.bufferBeforeMinutes),
                            range: 0...120,
                            step: 5
                        )
                        valueStepper(
                            title: "Buffer after",
                            valueText: "\(bookingPage.bufferAfterMinutes) min",
                            binding: binding(\.bufferAfterMinutes),
                            range: 0...120,
                            step: 5
                        )
                        valueStepper(
                            title: "Minimum notice",
                            valueText: "\(bookingPage.minimumNoticeMinutes) min",
                            binding: binding(\.minimumNoticeMinutes),
                            range: 0...10080,
                            step: 15
                        )
                    }
                    .padding(22)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .orbitGlassCard(radius: 24, fill: OrbitTheme.panelStrong)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Preview")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(OrbitTheme.textPrimary)
                        Text(bookingPage.title)
                            .font(.system(size: 28, weight: .semibold, design: .serif))
                            .foregroundStyle(OrbitTheme.textPrimary)
                        Text("30-second booking should feel predictable and low-friction.")
                            .foregroundStyle(OrbitTheme.textSecondary)

                        Rectangle()
                            .fill(OrbitTheme.divider)
                            .frame(height: 1)

                        previewRow("Slug", bookingPage.slug)
                        previewRow("Duration", "\(bookingPage.defaultDurationMinutes) min")
                        previewRow("Before buffer", "\(bookingPage.bufferBeforeMinutes) min")
                        previewRow("After buffer", "\(bookingPage.bufferAfterMinutes) min")
                        previewRow("Notice", "\(bookingPage.minimumNoticeMinutes) min")

                        Spacer()
                    }
                    .padding(22)
                    .frame(maxWidth: 320, maxHeight: .infinity, alignment: .topLeading)
                    .orbitGlassCard(radius: 24, fill: OrbitTheme.panelStrong)
                }

                HStack {
                    Text("Public URL preview: orbit.app/\(bookingPage.slug)")
                        .foregroundStyle(OrbitTheme.textSecondary)
                    Spacer()
                    Button("Save") {
                        Task {
                            await appState.saveBookingPage()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(OrbitTheme.accentStrong)
                }
            } else {
                ProgressView()
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .orbitGlassCard(radius: 30, fill: OrbitTheme.panelFill)
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<BookingPage, Value>) -> Binding<Value> {
        Binding(
            get: { appState.bookingPage![keyPath: keyPath] },
            set: { appState.bookingPage![keyPath: keyPath] = $0 }
        )
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(OrbitTheme.textMuted)
    }

    private func valueStepper(
        title: String,
        valueText: String,
        binding: Binding<Int>,
        range: ClosedRange<Int>,
        step: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .foregroundStyle(OrbitTheme.textSecondary)
                Spacer()
                Text(valueText)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(OrbitTheme.textPrimary)
            }

            Stepper("", value: binding, in: range, step: step)
                .labelsHidden()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(OrbitTheme.panelSoft, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func previewRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(OrbitTheme.textSecondary)
            Spacer()
            Text(value)
                .foregroundStyle(OrbitTheme.textPrimary)
        }
    }
}
