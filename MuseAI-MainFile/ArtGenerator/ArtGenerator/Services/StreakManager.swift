import Foundation
import SwiftUI

struct StreakReward {
    let day: Int
    let bonusCredits: Int
    let title: String
    let icon: String
}

@MainActor
class StreakManager: ObservableObject {
    static let shared = StreakManager()

    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var todayCompleted: Bool = false
    @Published var lastReward: StreakReward?

    private let streakKey = "currentStreak"
    private let longestStreakKey = "longestStreak"
    private let lastGenerationDateKey = "lastStreakGenerationDate"
    private let bonusCreditsKey = "bonusCreditsEarned"

    static let milestones: [StreakReward] = [
        StreakReward(day: 3, bonusCredits: 2, title: "3-Day Streak!", icon: "flame"),
        StreakReward(day: 7, bonusCredits: 5, title: "Week Warrior!", icon: "flame.fill"),
        StreakReward(day: 14, bonusCredits: 8, title: "Two Week Champion!", icon: "star.fill"),
        StreakReward(day: 30, bonusCredits: 15, title: "Monthly Master!", icon: "crown.fill"),
        StreakReward(day: 60, bonusCredits: 25, title: "60-Day Legend!", icon: "trophy.fill"),
        StreakReward(day: 100, bonusCredits: 50, title: "Century Creator!", icon: "medal.fill"),
    ]

    var bonusCredits: Int {
        get { UserDefaults.standard.integer(forKey: bonusCreditsKey) }
        set { UserDefaults.standard.set(newValue, forKey: bonusCreditsKey) }
    }

    var nextMilestone: StreakReward? {
        Self.milestones.first { $0.day > currentStreak }
    }

    var daysUntilNextReward: Int {
        guard let next = nextMilestone else { return 0 }
        return next.day - currentStreak
    }

    init() {
        loadStreak()
    }

    func recordGeneration() {
        let today = dateString(Date())
        let lastDate = UserDefaults.standard.string(forKey: lastGenerationDateKey) ?? ""

        if today == lastDate {
            todayCompleted = true
            return
        }

        let yesterday = dateString(Calendar.current.date(byAdding: .day, value: -1, to: Date())!)

        if lastDate == yesterday {
            currentStreak += 1
        } else if lastDate != today {
            currentStreak = 1
        }

        todayCompleted = true
        UserDefaults.standard.set(today, forKey: lastGenerationDateKey)

        if currentStreak > longestStreak {
            longestStreak = currentStreak
            UserDefaults.standard.set(longestStreak, forKey: longestStreakKey)
        }

        UserDefaults.standard.set(currentStreak, forKey: streakKey)

        checkMilestone()
    }

    private func checkMilestone() {
        if let reward = Self.milestones.first(where: { $0.day == currentStreak }) {
            bonusCredits += reward.bonusCredits
            lastReward = reward
            HapticManager.success()
        }
    }

    private func loadStreak() {
        currentStreak = UserDefaults.standard.integer(forKey: streakKey)
        longestStreak = UserDefaults.standard.integer(forKey: longestStreakKey)

        let today = dateString(Date())
        let yesterday = dateString(Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
        let lastDate = UserDefaults.standard.string(forKey: lastGenerationDateKey) ?? ""

        todayCompleted = (lastDate == today)

        if lastDate != today && lastDate != yesterday {
            currentStreak = 0
            UserDefaults.standard.set(0, forKey: streakKey)
        }
    }

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
