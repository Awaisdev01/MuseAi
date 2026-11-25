import AppIntents
import UIKit
import UserNotifications

@available(iOS 16.0, *)
struct GenerateImageIntent: AppIntent {

    static var title: LocalizedStringResource = "Generate Image with Muse AI"
    static var description = IntentDescription("Generate an image from a text description.")
    static var openAppWhenRun = true

    @Parameter(title: "Prompt", description: "Describe the image you want to create")
    var prompt: String

    @Parameter(title: "Style", default: "None")
    var style: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let notification = UNMutableNotificationContent()
        notification.title = "Generating your image..."
        notification.body = prompt
        notification.sound = .default
        let request = UNNotificationRequest(identifier: "intent_generate", content: notification, trigger: nil)
        try? await UNUserNotificationCenter.current().add(request)

        return .result(dialog: "Starting to generate: \(prompt)")
    }
}

@available(iOS 16.0, *)
struct SavePromptIntent: AppIntent {

    static var title: LocalizedStringResource = "Save Prompt to Library"
    static var description = IntentDescription("Save a prompt template to your library for reuse.")

    @Parameter(title: "Title")
    var title: String

    @Parameter(title: "Prompt")
    var prompt: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let template = PromptTemplate(title: title, prompt: prompt)
        PromptLibraryManager.shared.save(template)
        return .result(dialog: "Saved '\(title)' to your prompt library.")
    }
}

@available(iOS 16.0, *)
struct ViewGalleryIntent: AppIntent {

    static var title: LocalizedStringResource = "View Muse AI Gallery"
    static var description = IntentDescription("Open your Muse AI gallery.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}

@available(iOS 16.0, *)
struct ArtGeneratorShortcuts: AppShortcutsProvider {

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GenerateImageIntent(),
            phrases: [
                "Generate an image with \(.applicationName)",
                "Create an image with \(.applicationName)",
                "Make a picture with \(.applicationName)"
            ],
            shortTitle: "Generate Image",
            systemImageName: "sparkles"
        )
        AppShortcut(
            intent: ViewGalleryIntent(),
            phrases: [
                "Show my \(.applicationName) gallery",
                "Open \(.applicationName) gallery"
            ],
            shortTitle: "View Gallery",
            systemImageName: "photo.stack"
        )
    }
}
