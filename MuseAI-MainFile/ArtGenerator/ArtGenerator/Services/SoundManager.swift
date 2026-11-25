import AVFoundation
import UIKit

enum AppSound {
    case generate
    case success
    case tap
    case error
}

enum SoundManager {
    private static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
    }

    static func play(_ sound: AppSound) {
        guard isEnabled else { return }

        let soundID: SystemSoundID
        switch sound {
        case .generate:
            soundID = 1104
        case .success:
            soundID = 1025
        case .tap:
            soundID = 1104
        case .error:
            soundID = 1053
        }

        AudioServicesPlaySystemSound(soundID)
    }

    static func setEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "soundEnabled")
    }

    static var enabled: Bool {
        isEnabled
    }
}
