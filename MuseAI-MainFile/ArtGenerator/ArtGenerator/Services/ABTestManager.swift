import Foundation

enum PaywallVariant: String, CaseIterable {
    case yearlyFirst = "yearly_first"
    case lifetimeFirst = "lifetime_first"

    var tierOrder: [SubscriptionTier] {
        switch self {
        case .yearlyFirst: return [.yearly, .monthly, .lifetime]
        case .lifetimeFirst: return [.lifetime, .yearly, .monthly]
        }
    }

    var defaultSelection: SubscriptionTier {
        switch self {
        case .yearlyFirst: return .yearly
        case .lifetimeFirst: return .lifetime
        }
    }

    var headline: String {
        switch self {
        case .yearlyFirst: return "Unlock Your\nFull Creative Power"
        case .lifetimeFirst: return "Create Without\nLimits — Forever"
        }
    }
}

@MainActor
class ABTestManager: ObservableObject {
    static let shared = ABTestManager()

    @Published var paywallVariant: PaywallVariant

    private let variantKey = "ab_paywall_variant"
    private let impressionsKey = "ab_paywall_impressions"
    private let conversionsKey = "ab_paywall_conversions"

    init() {
        if let saved = UserDefaults.standard.string(forKey: variantKey),
           let variant = PaywallVariant(rawValue: saved) {
            self.paywallVariant = variant
        } else {
            let variant = PaywallVariant.allCases.randomElement() ?? .yearlyFirst
            UserDefaults.standard.set(variant.rawValue, forKey: variantKey)
            self.paywallVariant = variant
        }
    }

    func recordImpression() {
        let key = "\(impressionsKey)_\(paywallVariant.rawValue)"
        UserDefaults.standard.set(UserDefaults.standard.integer(forKey: key) + 1, forKey: key)
    }

    func recordConversion() {
        let key = "\(conversionsKey)_\(paywallVariant.rawValue)"
        UserDefaults.standard.set(UserDefaults.standard.integer(forKey: key) + 1, forKey: key)
    }

    var stats: (impressions: Int, conversions: Int, rate: Double) {
        let imp = UserDefaults.standard.integer(forKey: "\(impressionsKey)_\(paywallVariant.rawValue)")
        let conv = UserDefaults.standard.integer(forKey: "\(conversionsKey)_\(paywallVariant.rawValue)")
        return (imp, conv, imp > 0 ? Double(conv) / Double(imp) * 100 : 0)
    }
}
