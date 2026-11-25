import Foundation
import SwiftUI

struct Achievement: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let goal: Int
    let metric: AchievementMetric

    static func == (lhs: Achievement, rhs: Achievement) -> Bool { lhs.id == rhs.id }
}

enum AchievementMetric {
    case generations, favorites, streak, styles, collections, exports
}

@MainActor
final class AchievementManager: ObservableObject {
    static let shared = AchievementManager()

    @Published private(set) var unlockedIDs: Set<String> = []
    @Published var newlyUnlocked: Achievement?

    private var stylesUsed: Set<String> {
        get { Set((UserDefaults.standard.array(forKey: "achv_stylesUsed") as? [String]) ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: "achv_stylesUsed") }
    }

    private var exportCount: Int {
        get { UserDefaults.standard.integer(forKey: "achv_exportCount") }
        set { UserDefaults.standard.set(newValue, forKey: "achv_exportCount") }
    }

    static let all: [Achievement] = [
        Achievement(id: "first_creation", title: "First Spark", subtitle: "Generate your first image", icon: "sparkles", goal: 1, metric: .generations),
        Achievement(id: "creations_10", title: "Getting Started", subtitle: "Create 10 images", icon: "paintbrush.fill", goal: 10, metric: .generations),
        Achievement(id: "creations_50", title: "Prolific Artist", subtitle: "Create 50 images", icon: "paintpalette.fill", goal: 50, metric: .generations),
        Achievement(id: "creations_200", title: "Art Machine", subtitle: "Create 200 images", icon: "infinity", goal: 200, metric: .generations),
        Achievement(id: "favorites_5", title: "Curator", subtitle: "Favorite 5 images", icon: "heart.fill", goal: 5, metric: .favorites),
        Achievement(id: "favorites_25", title: "Connoisseur", subtitle: "Favorite 25 images", icon: "heart.circle.fill", goal: 25, metric: .favorites),
        Achievement(id: "streak_3", title: "Warming Up", subtitle: "Reach a 3-day streak", icon: "flame", goal: 3, metric: .streak),
        Achievement(id: "streak_7", title: "Week Warrior", subtitle: "Reach a 7-day streak", icon: "flame.fill", goal: 7, metric: .streak),
        Achievement(id: "streak_30", title: "Monthly Master", subtitle: "Reach a 30-day streak", icon: "crown.fill", goal: 30, metric: .streak),
        Achievement(id: "styles_5", title: "Style Explorer", subtitle: "Try 5 different art styles", icon: "wand.and.stars", goal: 5, metric: .styles),
        Achievement(id: "styles_all", title: "Style Master", subtitle: "Try every art style", icon: "star.circle.fill", goal: ArtStylePreset.allStyles.count, metric: .styles),
        Achievement(id: "collections_1", title: "Organizer", subtitle: "Create your first collection", icon: "folder.fill", goal: 1, metric: .collections),
        Achievement(id: "exports_10", title: "Sharer", subtitle: "Export 10 images", icon: "square.and.arrow.up.fill", goal: 10, metric: .exports),
    ]

    private init() {
        unlockedIDs = Set((UserDefaults.standard.array(forKey: "achv_unlocked") as? [String]) ?? [])
    }

    func progress(for achievement: Achievement, gallery: GalleryManager, streak: StreakManager) -> Int {
        switch achievement.metric {
        case .generations: return gallery.totalGenerationCount
        case .favorites: return gallery.favoriteArtworks.count
        case .streak: return streak.longestStreak
        case .styles: return stylesUsed.count
        case .collections: return gallery.collections.count
        case .exports: return exportCount
        }
    }

    func isUnlocked(_ achievement: Achievement) -> Bool { unlockedIDs.contains(achievement.id) }

    /// Call after any state change that might complete an achievement (generation, favorite, streak update, export).
    func refresh(gallery: GalleryManager, streak: StreakManager) {
        for achievement in Self.all where !unlockedIDs.contains(achievement.id) {
            if progress(for: achievement, gallery: gallery, streak: streak) >= achievement.goal {
                unlockedIDs.insert(achievement.id)
                newlyUnlocked = achievement
                HapticManager.success()
            }
        }
        UserDefaults.standard.set(Array(unlockedIDs), forKey: "achv_unlocked")
    }

    func recordStyleUsed(_ styleID: String) {
        guard styleID != ArtStylePreset.none.id else { return }
        var set = stylesUsed
        set.insert(styleID)
        stylesUsed = set
    }

    func recordExport() { exportCount += 1 }

    var unlockedCount: Int { unlockedIDs.count }
    var totalCount: Int { Self.all.count }
}
