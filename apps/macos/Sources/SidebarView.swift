import SwiftUI

struct SidebarView: View {
    @Binding var selection: AppSection

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Orbit")
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                    .foregroundStyle(OrbitTheme.textPrimary)
                Text("Calendar intelligence for macOS")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(OrbitTheme.textSecondary)
            }
            .padding(.top, 10)

            VStack(spacing: 10) {
                ForEach(AppSection.allCases) { section in
                    Button {
                        selection = section
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: iconName(for: section))
                                .frame(width: 18)
                            Text(section.rawValue)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                            Spacer()
                        }
                        .foregroundStyle(selection == section ? OrbitTheme.textPrimary : OrbitTheme.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(selection == section ? OrbitTheme.panelStrong : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(selection == section ? OrbitTheme.panelBorder : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                Text("Focused on calmer scheduling")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(OrbitTheme.textSecondary)
                Text("Less admin. Fewer clicks. Cleaner weeks.")
                    .font(.system(size: 16, weight: .medium, design: .serif))
                    .foregroundStyle(OrbitTheme.textPrimary)
            }
            .padding(16)
            .orbitGlassCard(radius: 22, fill: OrbitTheme.panelFill)
        }
        .padding(18)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.clear)
        .navigationSplitViewColumnWidth(min: 220, ideal: 240)
    }

    private func iconName(for section: AppSection) -> String {
        switch section {
        case .calendar:
            return "calendar"
        case .booking:
            return "link"
        case .settings:
            return "gearshape"
        }
    }
}
