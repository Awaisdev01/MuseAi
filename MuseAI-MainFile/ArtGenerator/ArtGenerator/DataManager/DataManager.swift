import UIKit
import SwiftUI
import Foundation

enum AppAppearance: String, CaseIterable, Identifiable {
    case dark, light, system
    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
    var colorScheme: ColorScheme? {
        switch self { case .dark: return .dark; case .light: return .light; case .system: return nil }
    }
}

@MainActor
class DataManager: ObservableObject {

    // MARK: - State
    @Published var promptText: String = ""
    @Published var negativePrompt: String = ""
    @Published var generatedImage: UIImage?
    @Published var batchImages: [UIImage] = []
    @Published var isGenerating: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var selectedStyle: ArtStylePreset = .none
    @Published var generationSettings = GenerationSettings()
    @Published var enhancedPrompt: String?
    @Published var generationProgress: String = ""
    @Published var recentPrompts: [String] = []
    @Published var batchCount: Int = 1
    @Published var sourceImage: UIImage?
    @Published var showStreakReward = false

    // MARK: - Preferences
    @AppStorage("appAppearance") var appearanceSetting: String = AppAppearance.dark.rawValue
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = false

    var appearance: AppAppearance {
        get { AppAppearance(rawValue: appearanceSetting) ?? .dark }
        set { appearanceSetting = newValue.rawValue }
    }

    // MARK: - Managers
    let storeKit = StoreKitManager.shared
    let gallery = GalleryManager.shared
    let network = NetworkMonitor.shared
    let notifications = NotificationManager.shared
    let review = ReviewManager.shared
    let streak = StreakManager.shared
    let abTest = ABTestManager.shared
    let achievements = AchievementManager.shared
    let referral = ReferralManager.shared

    // MARK: - Free Tier
    @AppStorage("dailyGenerationDate") private var dailyDateStr: String = ""
    @AppStorage("dailyGenerationCount") private var dailyCount: Int = 0

    private static let dateFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f
    }()

    var isPremium: Bool { storeKit.isPremium }

    var remainingFreeGenerations: Int {
        resetDailyIfNeeded()
        return max(0, AppConfig.freeGenerationsPerDay + streak.bonusCredits + referral.bonusCredits - dailyCount)
    }

    var canGenerate: Bool { isPremium || remainingFreeGenerations > 0 }

    init() { loadRecentPrompts() }

    // MARK: - Generate
    func generateArt() async {
        guard network.isConnected else { showErr("No internet connection."); return }
        guard !promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { showErr("Please enter a description."); return }
        guard canGenerate else { showErr("No free generations left today. Upgrade to Pro!"); return }

        isGenerating = true
        generatedImage = nil
        batchImages = []
        errorMessage = nil
        generationProgress = "Preparing..."
        HapticManager.impact()

        do {
            var finalPrompt = promptText

            if let src = sourceImage {
                generationProgress = "Analyzing image..."
                finalPrompt = try await OpenAIService.shared.analyzeImage(src, userPrompt: promptText, apiKey: AppConfig.apiKey)
                enhancedPrompt = finalPrompt
            } else if selectedStyle.id != ArtStylePreset.none.id {
                generationProgress = "Enhancing prompt..."
                finalPrompt = try await OpenAIService.shared.enhancePrompt(prompt: promptText, style: selectedStyle, apiKey: AppConfig.apiKey)
                enhancedPrompt = finalPrompt
            } else {
                enhancedPrompt = nil
            }

            let neg = negativePrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : negativePrompt
            generationProgress = "Generating..."

            if batchCount > 1 {
                let images = try await OpenAIService.shared.generateBatch(prompt: finalPrompt, negativePrompt: neg, settings: generationSettings, count: batchCount, apiKey: AppConfig.apiKey)
                batchImages = images; generatedImage = images.first
                incrementDaily(by: batchCount)
                gallery.saveBatchArt(images: images, prompt: promptText, enhancedPrompt: enhancedPrompt, style: selectedStyle, settings: generationSettings)
            } else {
                let image = try await OpenAIService.shared.generateImage(prompt: finalPrompt, negativePrompt: neg, settings: generationSettings, apiKey: AppConfig.apiKey)
                generatedImage = image
                incrementDaily()
                gallery.saveArt(image: image, prompt: promptText, enhancedPrompt: enhancedPrompt, style: selectedStyle, settings: generationSettings)
            }

            saveRecentPrompt(promptText)
            HapticManager.success()
            review.recordGeneration()
            streak.recordGeneration()
            achievements.recordStyleUsed(selectedStyle.id)
            achievements.refresh(gallery: gallery, streak: streak)
            if streak.lastReward != nil { showStreakReward = true }

            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                review.requestReviewIfAppropriate()
            }

        } catch let e as OpenAIError {
            HapticManager.error(); showErr(e.localizedDescription)
            print("⚠️ \(e.localizedDescription)")
        } catch {
            HapticManager.error(); showErr("Something went wrong: \(error.localizedDescription)")
            print("⚠️ \(error)")
        }

        isGenerating = false; generationProgress = ""
    }

    func saveToPhotos() {
        guard let img = generatedImage else { return }
        gallery.saveToPhotoLibrary(image: img)
        HapticManager.success()
    }

    func clearGeneration() {
        generatedImage = nil; batchImages = []; enhancedPrompt = nil
        promptText = ""; negativePrompt = ""; sourceImage = nil; batchCount = 1
        HapticManager.tap()
    }

    func useInspirationPrompt(_ prompt: String) { promptText = prompt; HapticManager.tap() }

    // MARK: - Recent
    private func saveRecentPrompt(_ p: String) {
        let t = p.trimmingCharacters(in: .whitespacesAndNewlines); guard !t.isEmpty else { return }
        recentPrompts.removeAll { $0 == t }; recentPrompts.insert(t, at: 0)
        if recentPrompts.count > 10 { recentPrompts = Array(recentPrompts.prefix(10)) }
        if let d = try? JSONEncoder().encode(recentPrompts) { UserDefaults.standard.set(d, forKey: "recentPrompts") }
    }

    private func loadRecentPrompts() {
        guard let d = UserDefaults.standard.data(forKey: "recentPrompts"),
              let p = try? JSONDecoder().decode([String].self, from: d) else { return }
        recentPrompts = p
    }

    private func showErr(_ msg: String) { errorMessage = msg; showError = true; HapticManager.error() }

    private func resetDailyIfNeeded() {
        let today = Self.dateFmt.string(from: Date())
        if dailyDateStr != today { dailyDateStr = today; dailyCount = 0 }
    }

    private func incrementDaily(by n: Int = 1) { resetDailyIfNeeded(); dailyCount += n }
}
