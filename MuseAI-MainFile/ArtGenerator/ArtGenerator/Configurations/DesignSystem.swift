import SwiftUI

// MARK: - Design Tokens
// Muse AI — Atelier Night: warm ink, rose accent, champagne gold
// Cinematic dark, glassmorphism, premium layered surfaces

enum DS {

    // MARK: - Color Tokens (Semantic)
    enum Colors {
        // Backgrounds — warm ink, never pure black
        static let bgDeep = Color(hex: "0C080A")
        static let bgBase = Color(hex: "100A0C")
        static let bgElevated = Color(hex: "160E12")
        static let bgCard = Color(hex: "1A1014")

        // Foreground
        static let textPrimary = Color(hex: "F6F0F2")
        static let textSecondary = Color(hex: "B8A8AE")
        static let textTertiary = Color(hex: "6E5C64")

        // Accent — atelier rose
        static let accent = Color(hex: "E11D74")
        static let accentLight = Color(hex: "F472B6")
        static let accentGlow = Color(hex: "E11D74").opacity(0.22)

        // Surfaces
        static let surface = Color.white.opacity(0.05)
        static let surfaceHover = Color.white.opacity(0.08)
        static let surfaceActive = Color.white.opacity(0.12)
        static let border = Color.white.opacity(0.08)
        static let borderFocused = Color(hex: "E11D74").opacity(0.5)

        // Semantic
        static let success = Color(hex: "34D399")
        static let error = Color(hex: "F87171")
        static let warning = Color(hex: "FBBF24")

        // Premium
        static let goldStart = Color(hex: "FFD700")
        static let goldEnd = Color(hex: "FFA500")
    }

    // MARK: - Gradients
    enum Gradients {
        static let accent = LinearGradient(
            colors: [Color(hex: "F472B6"), Color(hex: "E11D74"), Color(hex: "9D174D")],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        static let accentWide = LinearGradient(
            colors: [Color(hex: "F9A8D4"), Color(hex: "E11D74"), Color(hex: "9D174D")],
            startPoint: .leading, endPoint: .trailing
        )
        static let gold = LinearGradient(
            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        static let background = LinearGradient(
            colors: [Color(hex: "160E12"), Color(hex: "0C080A")],
            startPoint: .top, endPoint: .bottom
        )
        static let card = LinearGradient(
            colors: [Color.white.opacity(0.06), Color.white.opacity(0.02)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    // MARK: - Radius
    enum Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let pill: CGFloat = 100
    }

    // MARK: - Spacing (4pt grid)
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
        static let section: CGFloat = 40
    }

    // MARK: - Typography (SF Pro system)
    enum Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 17, weight: .regular)
        static let callout = Font.system(size: 16, weight: .regular)
        static let subheadline = Font.system(size: 15, weight: .regular)
        static let footnote = Font.system(size: 13, weight: .regular)
        static let caption1 = Font.system(size: 12, weight: .regular)
        static let caption2 = Font.system(size: 11, weight: .regular)
    }

    // MARK: - Animation (Spring physics, Expo.out easing)
    enum Motion {
        static let springResponse: Double = 0.45
        static let springDamping: Double = 0.82
        static let quick = Animation.easeOut(duration: 0.2)
        static let standard = Animation.spring(response: 0.45, dampingFraction: 0.82)
        static let slow = Animation.spring(response: 0.6, dampingFraction: 0.78)
        static let pressScale: CGFloat = 0.97
    }

    // MARK: - Shadows
    enum Shadow {
        static func card() -> some View {
            Color.black.opacity(0.3).blur(radius: 16).offset(y: 8)
        }
    }
}

// MARK: - Hex Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers

// Liquid Glass (iOS 26+) with a hand-tuned material fallback for iOS 16–25.
// Every card/button in the app routes through these two modifiers, so upgrading
// them upgrades the whole app's chrome in one place.
struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = DS.Radius.large
    var tint: Color? = nil

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(
                    tint.map { Glass.regular.tint($0) } ?? .regular,
                    in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                )
        } else {
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.35), DS.Colors.border, Color.white.opacity(0.05)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
        }
    }
}

struct SolidCard: ViewModifier {
    var cornerRadius: CGFloat = DS.Radius.large

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(DS.Colors.bgCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(DS.Colors.border, lineWidth: 1)
                    )
            )
    }
}

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? DS.Motion.pressScale : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(DS.Motion.quick, value: configuration.isPressed)
    }
}

struct AccentButton: ViewModifier {
    var isEnabled: Bool = true

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .font(DS.Typography.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .glassEffect(
                    Glass.regular.tint(DS.Colors.accent.opacity(isEnabled ? 1 : 0.4)).interactive(isEnabled),
                    in: RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous)
                )
        } else {
            content
                .font(DS.Typography.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    DS.Gradients.accent
                        .opacity(isEnabled ? 1 : 0.4)
                )
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous))
                .shadow(color: DS.Colors.accent.opacity(isEnabled ? 0.3 : 0), radius: 16, y: 8)
        }
    }
}

// MARK: - View Extensions
extension View {
    func glassCard(cornerRadius: CGFloat = DS.Radius.large, tint: Color? = nil) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius, tint: tint))
    }

    func solidCard(cornerRadius: CGFloat = DS.Radius.large) -> some View {
        modifier(SolidCard(cornerRadius: cornerRadius))
    }

    func accentButtonStyle(isEnabled: Bool = true) -> some View {
        modifier(AccentButton(isEnabled: isEnabled))
    }
}
