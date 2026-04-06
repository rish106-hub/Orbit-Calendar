import SwiftUI

enum OrbitTheme {
    static let backgroundTop = Color(red: 0.05, green: 0.15, blue: 0.33)
    static let backgroundMid = Color(red: 0.08, green: 0.24, blue: 0.49)
    static let backgroundBottom = Color(red: 0.15, green: 0.36, blue: 0.67)

    static let glowA = Color(red: 0.37, green: 0.62, blue: 1.00)
    static let glowB = Color(red: 0.58, green: 0.80, blue: 1.00)
    static let glowC = Color(red: 0.72, green: 0.86, blue: 1.00)

    static let panelFill = Color.white.opacity(0.14)
    static let panelStrong = Color.white.opacity(0.18)
    static let panelSoft = Color.white.opacity(0.10)
    static let panelBorder = Color.white.opacity(0.26)
    static let divider = Color.white.opacity(0.12)
    static let textPrimary = Color.white.opacity(0.95)
    static let textSecondary = Color.white.opacity(0.68)
    static let textMuted = Color.white.opacity(0.52)
    static let accent = Color(red: 0.57, green: 0.80, blue: 1.0)
    static let accentStrong = Color(red: 0.31, green: 0.65, blue: 1.0)
    static let eventTint = Color(red: 0.79, green: 0.90, blue: 1.0)

    static let shadow = Color.black.opacity(0.22)
}

struct OrbitGlassCard: ViewModifier {
    var radius: CGFloat = 28
    var fill: Color = OrbitTheme.panelFill
    var stroke: Color = OrbitTheme.panelBorder

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(fill)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(stroke, lineWidth: 1)
            )
            .shadow(color: OrbitTheme.shadow, radius: 32, x: 0, y: 20)
    }
}

extension View {
    func orbitGlassCard(radius: CGFloat = 28, fill: Color = OrbitTheme.panelFill, stroke: Color = OrbitTheme.panelBorder) -> some View {
        modifier(OrbitGlassCard(radius: radius, fill: fill, stroke: stroke))
    }
}

struct OrbitInlineField: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(OrbitTheme.panelSoft, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
            .foregroundStyle(OrbitTheme.textPrimary)
    }
}

extension View {
    func orbitInlineField() -> some View {
        modifier(OrbitInlineField())
    }
}
