import UIKit

enum HapticManager {

    private static var isDevice: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return true
        #endif
    }

    static func tap() {
        guard isDevice else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func impact() {
        guard isDevice else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func heavyImpact() {
        guard isDevice else { return }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    static func success() {
        guard isDevice else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func error() {
        guard isDevice else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    static func warning() {
        guard isDevice else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func selectionChanged() {
        guard isDevice else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
