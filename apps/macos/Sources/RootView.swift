import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: Binding(
                get: { appState.selectedSection },
                set: { appState.selectedSection = $0 }
            ))
        } detail: {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.95, blue: 0.92),
                        Color(red: 0.90, green: 0.91, blue: 0.86),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

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
                .padding(24)
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
    }
}
