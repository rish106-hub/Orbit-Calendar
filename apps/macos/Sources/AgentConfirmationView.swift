import SwiftUI

struct AgentConfirmationView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Confirm Action")
                .font(.system(size: 24, weight: .semibold, design: .rounded))

            if let action = appState.pendingAction {
                Text(action.toolName)
                    .foregroundStyle(.secondary)

                ForEach(action.arguments.keys.sorted(), id: \.self) { key in
                    HStack {
                        Text(key)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(action.arguments[key] ?? "")
                    }
                }
            }

            HStack {
                Button("Cancel", role: .cancel) {
                    appState.pendingAction = nil
                    dismiss()
                }
                Spacer()
                Button("Confirm") {
                    Task {
                        await appState.confirmPendingAction()
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 420)
    }
}
