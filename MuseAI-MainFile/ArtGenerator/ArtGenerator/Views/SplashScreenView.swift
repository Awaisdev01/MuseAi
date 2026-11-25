import SwiftUI

struct SplashScreenView: View {
    @State private var iconScale: CGFloat = 0.6
    @State private var iconOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.3
    @State private var ringOpacity: Double = 0
    @Binding var isFinished: Bool

    var body: some View {
        ZStack {
            DS.Gradients.background.ignoresSafeArea()

            ZStack {
                Circle()
                    .strokeBorder(DS.Gradients.accent, lineWidth: 2)
                    .frame(width: 120, height: 120)
                    .scaleEffect(ringScale)
                    .opacity(ringOpacity)

                VStack(spacing: DS.Spacing.lg) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 52, weight: .light))
                        .foregroundStyle(DS.Gradients.accent)
                        .scaleEffect(iconScale)
                        .opacity(iconOpacity)

                    VStack(spacing: DS.Spacing.xs) {
                        Text(AppConfig.appName)
                            .font(DS.Typography.title2)
                            .foregroundColor(DS.Colors.textPrimary)
                        Text(AppConfig.appTagline)
                            .font(DS.Typography.subheadline)
                            .foregroundColor(DS.Colors.textSecondary)
                    }
                    .opacity(textOpacity)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                iconScale = 1.0
                iconOpacity = 1
            }
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
                ringScale = 1.0
                ringOpacity = 0.5
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                textOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.3).delay(0.3)) {
                ringOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                withAnimation(.easeIn(duration: 0.3)) {
                    isFinished = true
                }
            }
        }
    }
}
