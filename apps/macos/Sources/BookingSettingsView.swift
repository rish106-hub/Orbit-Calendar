import SwiftUI

struct BookingSettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Booking Link")
                .font(.system(size: 30, weight: .semibold, design: .serif))

            if let bookingPage = appState.bookingPage {
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
}
