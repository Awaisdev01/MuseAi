import UIKit
import SwiftUI

struct QueuedGeneration: Identifiable {
    let id = UUID()
    let prompt: String
    var negativePrompt: String? = nil
    let style: ArtStylePreset
    let settings: GenerationSettings
    var status: QueueStatus = .pending

    enum QueueStatus: Equatable {
        case pending, generating, completed(UIImage), failed(String)
    }
}

@MainActor
class GenerationQueue: ObservableObject {
    static let shared = GenerationQueue()

    @Published var queue: [QueuedGeneration] = []
    @Published var isProcessing = false

    var pendingCount: Int { queue.filter { $0.status == .pending }.count }
    var completedCount: Int { queue.filter { if case .completed = $0.status { return true }; return false }.count }

    func enqueue(prompt: String, negativePrompt: String? = nil, style: ArtStylePreset, settings: GenerationSettings) {
        queue.append(QueuedGeneration(prompt: prompt, negativePrompt: negativePrompt, style: style, settings: settings))
        HapticManager.tap()
        if !isProcessing { Task { await processQueue() } }
    }

    func removeCompleted() {
        queue.removeAll { if case .completed = $0.status { return true }; if case .failed = $0.status { return true }; return false }
    }

    func clearAll() { queue.removeAll(); isProcessing = false }

    private func processQueue() async {
        isProcessing = true
        while let idx = queue.firstIndex(where: { $0.status == .pending }) {
            queue[idx].status = .generating
            do {
                var finalPrompt = queue[idx].prompt
                let style = queue[idx].style

                if style.id != ArtStylePreset.none.id {
                    finalPrompt = try await OpenAIService.shared.enhancePrompt(prompt: finalPrompt, style: style, apiKey: AppConfig.apiKey)
                }

                let image = try await OpenAIService.shared.generateImage(
                    prompt: finalPrompt, negativePrompt: queue[idx].negativePrompt,
                    settings: queue[idx].settings, apiKey: AppConfig.apiKey
                )
                queue[idx].status = .completed(image)
                GalleryManager.shared.saveArt(
                    image: image, prompt: queue[idx].prompt,
                    enhancedPrompt: style.id != ArtStylePreset.none.id ? finalPrompt : nil,
                    style: style, settings: queue[idx].settings
                )
                HapticManager.success()
            } catch {
                queue[idx].status = .failed(error.localizedDescription)
                HapticManager.error()
            }
        }
        isProcessing = false
    }
}
