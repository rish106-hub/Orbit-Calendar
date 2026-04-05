import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Settings")
                .font(.system(size: 30, weight: .semibold, design: .serif))

            if let profile = appState.profile {
                HStack(alignment: .top, spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        settingsRow("Display name", profile.displayName ?? "Orbit Dev User")
                        settingsRow("Email", profile.email)
                        settingsRow("Timezone", profile.defaultTimezone)
                        settingsRow("Mode", profile.mode)
                        settingsRow("Calendar provider", profile.calendarProvider)
                        settingsRow("API", appState.apiBaseURL.absoluteString)
                    }
                    .padding(22)
                    .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 24))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Provider")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                        Text("Routes already talk through a provider seam. `local` is active now, and `google` can replace it later without changing the macOS client contract.")
                            .foregroundStyle(.secondary)
                    }
                    .padding(22)
                    .frame(maxWidth: 320, alignment: .topLeading)
                    .background(Color.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 24))
                }
            } else {
                ProgressView()
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func settingsRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
    }
}
