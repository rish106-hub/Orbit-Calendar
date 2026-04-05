import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Settings")
                .font(.system(size: 30, weight: .semibold, design: .serif))
                .foregroundStyle(OrbitTheme.textPrimary)

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
                            .foregroundStyle(OrbitTheme.textPrimary)
                        Text("Routes already talk through a provider seam. `local` is active now, and `google` can replace it later without changing the macOS client contract.")
                            .foregroundStyle(OrbitTheme.textSecondary)
                    }
                    .padding(22)
                    .frame(maxWidth: 320, alignment: .topLeading)
                    .orbitGlassCard(radius: 24, fill: OrbitTheme.panelStrong)
                }
            } else {
                ProgressView()
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .orbitGlassCard(radius: 30, fill: OrbitTheme.panelFill)
    }

    private func settingsRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(OrbitTheme.textSecondary)
            Spacer()
            Text(value)
                .foregroundStyle(OrbitTheme.textPrimary)
        }
    }
}
