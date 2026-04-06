import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Settings")
                    .font(.system(size: 30, weight: .semibold, design: .serif))
                    .foregroundStyle(OrbitTheme.textPrimary)
                Text("Account identity, backend connection, and provider configuration.")
                    .foregroundStyle(OrbitTheme.textSecondary)
            }

            if let profile = appState.profile {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .top, spacing: 20) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Profile")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundStyle(OrbitTheme.textPrimary)
                            Text("Your local Orbit identity and connection details.")
                                .foregroundStyle(OrbitTheme.textSecondary)

                            Rectangle()
                                .fill(OrbitTheme.divider)
                                .frame(height: 1)

                            settingsRow("Display name", profile.displayName ?? "Orbit Dev User")
                            settingsRow("Email", profile.email)
                            settingsRow("Timezone", profile.defaultTimezone)
                            settingsRow("Mode", profile.mode.replacingOccurrences(of: "_", with: " ").capitalized)
                            settingsRow("Calendar provider", profile.calendarProvider.capitalized)
                            settingsRow("API", appState.apiBaseURL.absoluteString)
                        }
                        .padding(22)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .orbitGlassCard(radius: 24, fill: OrbitTheme.panelStrong)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Session")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundStyle(OrbitTheme.textPrimary)
                            Text("Routes already talk through a provider seam. `local` is active now, and `google` can replace it later without changing the macOS client contract.")
                                .foregroundStyle(OrbitTheme.textSecondary)

                            Rectangle()
                                .fill(OrbitTheme.divider)
                                .frame(height: 1)

                            statusBadge("Auth", profile.mode.replacingOccurrences(of: "_", with: " ").capitalized)
                            statusBadge("Provider", profile.calendarProvider.capitalized)

                            Button("Log Out") {
                                Task {
                                    await appState.logout()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(OrbitTheme.accentStrong)
                        }
                        .padding(22)
                        .frame(maxWidth: 320, alignment: .topLeading)
                        .orbitGlassCard(radius: 24, fill: OrbitTheme.panelStrong)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Backend")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(OrbitTheme.textPrimary)
                        Text("Point the app at a local or hosted API without rebuilding the macOS client.")
                            .foregroundStyle(OrbitTheme.textSecondary)

                        Rectangle()
                            .fill(OrbitTheme.divider)
                            .frame(height: 1)

                        TextField(
                            "http://127.0.0.1:8001",
                            text: Binding(
                                get: { appState.apiBaseURLInput },
                                set: { appState.apiBaseURLInput = $0 }
                            )
                        )
                        .orbitInlineField()

                        HStack(spacing: 12) {
                            Button("Reconnect to Backend") {
                                Task {
                                    await appState.applyAPIBaseURL()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(OrbitTheme.accentStrong)

                            Button("Refresh Status") {
                                Task {
                                    await appState.refreshAuthServiceStatus()
                                }
                            }
                            .buttonStyle(.bordered)
                            .tint(OrbitTheme.accent)
                        }

                        backendStatusRow
                    }
                    .padding(22)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
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
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(OrbitTheme.textSecondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(OrbitTheme.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(OrbitTheme.panelSoft, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func statusBadge(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(OrbitTheme.textMuted)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(OrbitTheme.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(OrbitTheme.panelSoft, in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var backendStatusRow: some View {
        switch appState.authServiceState {
        case .checking:
            statusBadge("Backend", "Checking")
        case .ready:
            statusBadge("Backend", "Online")
        case .degraded(let message):
            VStack(alignment: .leading, spacing: 8) {
                statusBadge("Backend", "Needs Attention")
                Text(message)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(OrbitTheme.textSecondary)
            }
        }
    }
}
