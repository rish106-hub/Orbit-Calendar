import SwiftUI

struct SidebarView: View {
    @Binding var selection: AppSection

    var body: some View {
        List(AppSection.allCases, selection: $selection) { section in
            Label(section.rawValue, systemImage: iconName(for: section))
                .tag(section)
        }
        .navigationSplitViewColumnWidth(min: 180, ideal: 200)
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
