import SwiftUI

struct RootView: View {
    var body: some View {
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

            VStack(alignment: .leading, spacing: 24) {
                Text("Orbit Calendar")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)

                Text("AI that helps you act on your calendar.")
                    .font(.system(size: 54, weight: .semibold, design: .serif))
                    .lineLimit(2)

                Text("Native macOS scaffold for the Orbit MVP. Product logic is intentionally not implemented yet.")
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 620, alignment: .leading)
            }
            .padding(48)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .padding(24)
            )
        }
    }
}
