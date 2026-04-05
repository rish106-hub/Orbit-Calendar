import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            backgroundLayer

            if appState.profile == nil {
                AuthView()
                    .padding(20)
            } else {
                HStack(spacing: 18) {
                    SidebarView(
                        selection: Binding(
                            get: { appState.selectedSection },
                            set: { appState.selectedSection = $0 }
                        )
                    )
                    .frame(width: 248)
                    .orbitGlassCard(radius: 30, fill: OrbitTheme.panelFill)

                    Group {
                        switch appState.selectedSection {
                        case .calendar:
                            CalendarWorkspaceView()
                        case .booking:
                            BookingSettingsView()
                        case .settings:
                            SettingsView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(20)
            }
        }
        .task {
            await appState.bootstrap()
        }
        .alert(
            "Orbit Error",
            isPresented: Binding(
                get: { appState.errorMessage != nil },
                set: { newValue in
                    if !newValue {
                        appState.errorMessage = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                appState.errorMessage = nil
            }
        } message: {
            Text(appState.errorMessage ?? "")
        }
        .sheet(isPresented: Binding(
            get: { appState.pendingAction != nil },
            set: { visible in
                if !visible {
                    appState.pendingAction = nil
                }
            }
        )) {
            AgentConfirmationView()
        }
        .preferredColorScheme(.dark)
    }

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [
                    OrbitTheme.backgroundTop,
                    OrbitTheme.backgroundMid,
                    OrbitTheme.backgroundBottom,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    OrbitTheme.glowA.opacity(0.46),
                    Color.clear,
                ],
                center: .topLeading,
                startRadius: 40,
                endRadius: 420
            )
            .offset(x: -80, y: -80)

            RadialGradient(
                colors: [
                    OrbitTheme.glowB.opacity(0.32),
                    Color.clear,
                ],
                center: .trailing,
                startRadius: 30,
                endRadius: 360
            )
            .offset(x: 120, y: 10)

            RadialGradient(
                colors: [
                    OrbitTheme.glowC.opacity(0.18),
                    Color.clear,
                ],
                center: .bottomLeading,
                startRadius: 20,
                endRadius: 300
            )
            .offset(x: -140, y: 180)

            GeometryReader { geometry in
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    stride(from: 0.0, through: width, by: 56).forEach { x in
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: height))
                    }
                    stride(from: 0.0, through: height, by: 56).forEach { y in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                }
                .stroke(Color.white.opacity(0.035), lineWidth: 1)
            }
        }
        .ignoresSafeArea()
    }
}
