import SwiftUI

struct OnboardingView: View {

    @Binding var hasSeenOnboarding: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentPage = 0

    private let pages: [(icon: String, title: String, subtitle: String, gradient: [Color])] = [
        ("sparkles", "Meet Muse AI",
         "Turn a simple idea into a finished image in seconds. Your studio, in your pocket.",
         [Color(hex: "F472B6"), Color(hex: "E11D74")]),
        ("paintbrush.pointed.fill", "Twelve Signature Styles",
         "Photorealistic, anime, oil painting, pixel art, cinematic — pick your aesthetic.",
         [Color(hex: "EC4899"), Color(hex: "9D174D")]),
        ("photo.stack.fill", "Your Personal Studio",
         "Every creation is saved automatically. Organize favorites, collections, and prompts.",
         [Color(hex: "F59E0B"), Color(hex: "E11D74")]),
        ("crown.fill", "Five Free Images Daily",
         "Start creating right now. Upgrade anytime for unlimited Muse AI access.",
         [Color(hex: "F59E0B"), Color(hex: "EF4444")])
    ]

    var body: some View {
        ZStack {
            DS.Gradients.background.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPage(
                            icon: pages[index].icon,
                            title: pages[index].title,
                            subtitle: pages[index].subtitle,
                            gradientColors: pages[index].gradient
                        ).tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                VStack(spacing: DS.Spacing.xxl) {
                    PageDots(current: currentPage, total: pages.count)

                    Button {
                        HapticManager.impact()
                        if currentPage < pages.count - 1 {
                            withAnimation(reduceMotion ? .none : DS.Motion.standard) {
                                currentPage += 1
                            }
                        } else {
                            withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.3)) {
                                hasSeenOnboarding = true
                            }
                        }
                    } label: {
                        Text(currentPage < pages.count - 1 ? "Continue" : "Start Creating")
                            .accentButtonStyle()
                    }
                    .buttonStyle(PressableStyle())
                    .padding(.horizontal, DS.Spacing.xxxl)

                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            HapticManager.tap()
                            withAnimation { hasSeenOnboarding = true }
                        }
                        .font(DS.Typography.subheadline)
                        .foregroundColor(DS.Colors.textTertiary)
                    } else {
                        Color.clear.frame(height: 20)
                    }
                }
                .padding(.bottom, 44)
            }
        }
    }
}

// MARK: - Page
private struct OnboardingPage: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradientColors: [Color]

    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: DS.Spacing.xxl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(LinearGradient(colors: gradientColors.map { $0.opacity(0.12) },
                                          startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 160, height: 160)
                    .scaleEffect(appeared ? 1 : 0.7)

                if !reduceMotion {
                    Circle()
                        .stroke(LinearGradient(colors: gradientColors.map { $0.opacity(0.15) },
                                               startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                        .frame(width: 200, height: 200)
                        .scaleEffect(appeared ? 1 : 0.5)
                        .opacity(appeared ? 1 : 0)
                }

                Image(systemName: icon)
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .scaleEffect(appeared ? 1 : 0.6)
                    .opacity(appeared ? 1 : 0)
            }
            .accessibilityHidden(true)

            VStack(spacing: DS.Spacing.md) {
                Text(title)
                    .font(DS.Typography.title1)
                    .foregroundColor(DS.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(DS.Typography.body)
                    .foregroundColor(DS.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.1)) {
                appeared = true
            }
        }
        .onDisappear { appeared = false }
    }
}

// MARK: - Dots
private struct PageDots: View {
    let current: Int; let total: Int

    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index == current ? DS.Colors.accent : DS.Colors.textTertiary.opacity(0.4))
                    .frame(width: index == current ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: current)
            }
        }
        .accessibilityLabel("Page \(current + 1) of \(total)")
    }
}
