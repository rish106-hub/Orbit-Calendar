import SwiftUI

private enum AuthField: Hashable {
    case email
    case password
    case displayName
    case timezone
}

struct AuthView: View {
    @Environment(AppState.self) private var appState
    @FocusState private var focusedField: AuthField?

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

                authStatusBanner

                field("Email", text: Binding(
                    get: { appState.authEmail },
                    set: { appState.authEmail = $0 }
                ), field: .email)

                SecureField(
                    "",
                    text: Binding(
                        get: { appState.authPassword },
                        set: { appState.authPassword = $0 }
                    ),
                    prompt: Text("Password").foregroundStyle(OrbitTheme.textMuted)
                )
                .focused($focusedField, equals: .password)
                .orbitInlineField()
                .onSubmit {
                    if appState.authMode == .signup {
                        focusedField = .displayName
                    } else {
                        Task { await appState.submitAuth() }
                    }
                }

                if appState.authMode == .signup {
                    field("Display name", text: Binding(
                        get: { appState.authDisplayName },
                        set: { appState.authDisplayName = $0 }
                    ), field: .displayName)

                    field("Timezone", text: Binding(
                        get: { appState.authTimezone },
                        set: { appState.authTimezone = $0 }
                    ), field: .timezone)
                }

                Button(appState.authMode == .login ? "Log In" : "Create Account") {
                    Task {
                        await appState.submitAuth()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(OrbitTheme.accentStrong)
                .disabled(appState.isLoading)

                if let errorMessage = appState.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(red: 1.0, green: 0.78, blue: 0.80))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(width: 380)
            .padding(30)
            .orbitGlassCard(radius: 30, fill: OrbitTheme.panelFill)
        }
        .onAppear {
            focusedField = .email
        }
        .onChange(of: appState.authMode) { _, _ in
            focusedField = .email
        }
    }

    private func field(_ placeholder: String, text: Binding<String>, field: AuthField) -> some View {
        TextField(
            "",
            text: text,
            prompt: Text(placeholder).foregroundStyle(OrbitTheme.textMuted)
        )
        .focused($focusedField, equals: field)
        .orbitInlineField()
        .onSubmit {
            switch field {
            case .email:
                focusedField = .password
            case .password:
                if appState.authMode == .signup {
                    focusedField = .displayName
                } else {
                    Task { await appState.submitAuth() }
                }
            case .displayName:
                focusedField = .timezone
            case .timezone:
                Task { await appState.submitAuth() }
            }
        }
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

    @ViewBuilder
    private var authStatusBanner: some View {
        switch appState.authServiceState {
        case .checking:
            HStack(spacing: 10) {
                ProgressView()
                    .controlSize(.small)
                Text("Checking account service...")
                    .foregroundStyle(OrbitTheme.textSecondary)
            }
            .font(.system(size: 13, weight: .medium, design: .rounded))
        case .ready:
            Label("Account service is online", systemImage: "checkmark.circle.fill")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color(red: 0.69, green: 0.90, blue: 1.0))
        case .degraded(let message):
            VStack(alignment: .leading, spacing: 10) {
                Label("Account service needs attention", systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(red: 1.0, green: 0.84, blue: 0.62))
                Text(message)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(OrbitTheme.textSecondary)
                Button("Retry Connection") {
                    Task {
                        await appState.refreshAuthServiceStatus()
                    }
                }
                .buttonStyle(.bordered)
                .tint(OrbitTheme.accent)
            }
            .padding(14)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.10), lineWidth: 1))
        }
    }
}
