import SwiftUI

struct BookingSettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Booking Link")
                        .font(.system(size: 30, weight: .semibold, design: .serif))
                    Text("One public link for the MVP, with buffers and notice controls.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let bookingPage = appState.bookingPage {
                    Text("orbit.app/\(bookingPage.slug)")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.58), in: Capsule())
                }
            }

            if let bookingPage = appState.bookingPage {
                HStack(alignment: .top, spacing: 20) {
                    Form {
                        TextField("Slug", text: binding(\.slug))
                        TextField("Title", text: binding(\.title))
                        Toggle("Active", isOn: binding(\.active))
                        Stepper("Duration: \(bookingPage.defaultDurationMinutes) min", value: binding(\.defaultDurationMinutes), in: 15...180, step: 15)
                        Stepper("Buffer before: \(bookingPage.bufferBeforeMinutes) min", value: binding(\.bufferBeforeMinutes), in: 0...120, step: 5)
                        Stepper("Buffer after: \(bookingPage.bufferAfterMinutes) min", value: binding(\.bufferAfterMinutes), in: 0...120, step: 5)
                        Stepper("Minimum notice: \(bookingPage.minimumNoticeMinutes) min", value: binding(\.minimumNoticeMinutes), in: 0...10080, step: 15)
                    }
                    .formStyle(.grouped)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Preview")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                        Text(bookingPage.title)
                            .font(.system(size: 28, weight: .semibold, design: .serif))
                        Text("30-second booking should feel predictable and low-friction.")
                            .foregroundStyle(.secondary)

                        Divider()

                        previewRow("Slug", bookingPage.slug)
                        previewRow("Duration", "\(bookingPage.defaultDurationMinutes) min")
                        previewRow("Before buffer", "\(bookingPage.bufferBeforeMinutes) min")
                        previewRow("After buffer", "\(bookingPage.bufferAfterMinutes) min")
                        previewRow("Notice", "\(bookingPage.minimumNoticeMinutes) min")

                        Spacer()
                    }
                    .padding(22)
                    .frame(maxWidth: 320, maxHeight: .infinity, alignment: .topLeading)
                    .background(Color.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 24))
                }

                HStack {
                    Text("Public URL preview: orbit.app/\(bookingPage.slug)")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Save") {
                        Task {
                            await appState.saveBookingPage()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                ProgressView()
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<BookingPage, Value>) -> Binding<Value> {
        Binding(
            get: { appState.bookingPage![keyPath: keyPath] },
            set: { appState.bookingPage![keyPath: keyPath] = $0 }
        )
    }

    private func previewRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
    }
}
