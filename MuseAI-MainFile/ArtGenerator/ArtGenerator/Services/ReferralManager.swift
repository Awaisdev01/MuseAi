import Foundation
import SwiftUI

/// Grants a small bonus generation credit once per day when the user shares the app,
/// turning organic word-of-mouth into a lightweight growth loop.
@MainActor
final class ReferralManager: ObservableObject {
    static let shared = ReferralManager()

    static let creditsPerShare = 1
    static let maxBonusCredits = 30

    @Published private(set) var bonusCredits: Int
    @Published private(set) var hasEarnedToday: Bool = false

    private let bonusKey = "referral_bonusCredits"
    private let lastShareDateKey = "referral_lastShareDate"

    private static let dateFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f
    }()

    private init() {
        bonusCredits = UserDefaults.standard.integer(forKey: bonusKey)
        hasEarnedToday = UserDefaults.standard.string(forKey: lastShareDateKey) == Self.dateFmt.string(from: Date())
    }

    /// Call after the share sheet completes with a successful/unknown outcome.
    @discardableResult
    func recordShare() -> Bool {
        let today = Self.dateFmt.string(from: Date())
        guard UserDefaults.standard.string(forKey: lastShareDateKey) != today else { return false }
        guard bonusCredits < Self.maxBonusCredits else { return false }

        UserDefaults.standard.set(today, forKey: lastShareDateKey)
        bonusCredits += Self.creditsPerShare
        UserDefaults.standard.set(bonusCredits, forKey: bonusKey)
        hasEarnedToday = true
        HapticManager.success()
        return true
    }
}
