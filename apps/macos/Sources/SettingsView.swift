import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Settings")
                .font(.system(size: 30, weight: .semibold, design: .serif))

            if let profile = appState.profile {
                VStack(alignment: .leading, spacing: 12) {
                    settingsRow("Display name", profile.displayName ?? "Orbit Dev User")
                    settingsRow("Email", profile.email)
                    settingsRow("Timezone", profile.defaultTimezone)
                    settingsRow("Mode", profile.mode)
                    settingsRow("API", appState.apiBaseURL.absoluteString)
                }
                .padding(22)
                .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 24))
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
