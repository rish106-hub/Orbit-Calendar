import SwiftUI

struct AuthView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(spacing: 28) {
            VStack(alignment: .leading, spacing: 18) {
                Text("Orbit Calendar")
                    .font(.system(size: 42, weight: .semibold, design: .serif))
                    .foregroundStyle(OrbitTheme.textPrimary)
                Text("Professional scheduling, booking, and calendar actions in one native macOS app.")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(OrbitTheme.textSecondary)

                VStack(alignment: .leading, spacing: 10) {
                    authPoint("Protected local account flow")
                    authPoint("Native desktop calendar workspace")
                    authPoint("Agent actions with confirmation")
                    authPoint("Booking page with timezone-aware slots")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(34)
            .orbitGlassCard(radius: 34, fill: OrbitTheme.panelStrong)

            VStack(alignment: .leading, spacing: 16) {
                Picker("Auth mode", selection: Binding(
                    get: { appState.authMode },
                    set: { appState.authMode = $0 }
                )) {
                    Text("Log In").tag(AuthMode.login)
                    Text("Sign Up").tag(AuthMode.signup)
                }
                .pickerStyle(.segmented)

                Text(appState.authMode == .login ? "Welcome back" : "Create your account")
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .foregroundStyle(OrbitTheme.textPrimary)

                field("Email", text: Binding(
                    get: { appState.authEmail },
                    set: { appState.authEmail = $0 }
                ))

                SecureField("Password", text: Binding(
                    get: { appState.authPassword },
                    set: { appState.authPassword = $0 }
                ))
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.10), lineWidth: 1))
                .foregroundStyle(OrbitTheme.textPrimary)

                if appState.authMode == .signup {
                    field("Display name", text: Binding(
                        get: { appState.authDisplayName },
                        set: { appState.authDisplayName = $0 }
                    ))
                    field("Timezone", text: Binding(
                        get: { appState.authTimezone },
                        set: { appState.authTimezone = $0 }
                    ))
                }

                Button(appState.authMode == .login ? "Log In" : "Create Account") {
                    Task {
                        await appState.submitAuth()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(OrbitTheme.accentStrong)
            }
            .frame(width: 380)
            .padding(30)
            .orbitGlassCard(radius: 30, fill: OrbitTheme.panelFill)
        }
    }

    private func field(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .textFieldStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.10), lineWidth: 1))
            .foregroundStyle(OrbitTheme.textPrimary)
    }

    private func authPoint(_ text: String) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(OrbitTheme.accent)
                .frame(width: 8, height: 8)
            Text(text)
                .foregroundStyle(OrbitTheme.textSecondary)
        }
    }
}
