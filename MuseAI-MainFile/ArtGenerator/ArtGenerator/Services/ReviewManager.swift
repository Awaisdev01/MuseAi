import StoreKit
import UIKit

@MainActor
class ReviewManager: ObservableObject {
    static let shared = ReviewManager()

    @Published var shouldShowReview = false

    private let generationsBeforeReview = 3
    private let minDaysBetweenReviews = 60
    private let reviewCountKey = "reviewRequestCount"
    private let lastReviewDateKey = "lastReviewRequestDate"
    private let totalGenerationsKey = "totalGenerationsForReview"

    private var totalGenerations: Int {
        get { UserDefaults.standard.integer(forKey: totalGenerationsKey) }
        set { UserDefaults.standard.set(newValue, forKey: totalGenerationsKey) }
    }

    private var reviewCount: Int {
        get { UserDefaults.standard.integer(forKey: reviewCountKey) }
        set { UserDefaults.standard.set(newValue, forKey: reviewCountKey) }
    }

    private var lastReviewDate: Date? {
        get { UserDefaults.standard.object(forKey: lastReviewDateKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: lastReviewDateKey) }
    }

    func recordGeneration() {
        totalGenerations += 1
        checkIfShouldPrompt()
    }

    func requestReviewIfAppropriate() {
        guard shouldShowReview else { return }
        guard reviewCount < 3 else { return }

        if let lastDate = lastReviewDate {
            let daysSince = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            guard daysSince >= minDaysBetweenReviews else { return }
        }

        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        SKStoreReviewController.requestReview(in: scene)

        reviewCount += 1
        lastReviewDate = Date()
        shouldShowReview = false
    }

    private func checkIfShouldPrompt() {
        let milestones = [3, 10, 25, 50, 100]
        if milestones.contains(totalGenerations) {
            shouldShowReview = true
        }
    }
}
