import SwiftUI

@main
struct ArtGeneratorApp: App {

    @StateObject private var manager = DataManager()
    @AppStorage(AppConfig.hasSeenOnboardingKey) private var hasSeenOnboarding = false
    @State private var splashFinished = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if !splashFinished {
                    SplashScreenView(isFinished: $splashFinished)
                        .transition(.opacity)
                } else if !hasSeenOnboarding {
                    OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
                        .transition(.opacity)
                } else {
                    DashboardContentView()
                        .environmentObject(manager)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: splashFinished)
            .animation(.easeInOut(duration: 0.3), value: hasSeenOnboarding)
            .preferredColorScheme(manager.appearance.colorScheme ?? .dark)
            .tint(DS.Colors.accent)
        }
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }
}

extension Text {
    func foregroundLinearGradient(colors: [Color], startPoint: UnitPoint, endPoint: UnitPoint) -> some View {
        overlay(
            LinearGradient(colors: colors, startPoint: startPoint, endPoint: endPoint)
                .mask(self)
        )
    }
}
