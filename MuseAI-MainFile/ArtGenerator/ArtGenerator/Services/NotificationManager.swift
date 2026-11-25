import UserNotifications
import UIKit

@MainActor
class NotificationManager: ObservableObject {

    static let shared = NotificationManager()

    @Published var isAuthorized = false

    private let center = UNUserNotificationCenter.current()

    init() {
        Task { await checkAuthorization() }
    }

    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            if granted {
                scheduleDailyReminder()
            }
            return granted
        } catch {
            return false
        }
    }

    func checkAuthorization() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    func scheduleDailyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["daily_generations"])

        let content = UNMutableNotificationContent()
        content.title = "Your Free Creations Are Ready! ✨"
        content.body = "You have 5 free Muse AI generations waiting. What will you create today?"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_generations", content: content, trigger: trigger)

        center.add(request)
    }

    func scheduleGenerationComplete(prompt: String) {
        let content = UNMutableNotificationContent()
        content.title = "Your Image Is Ready!"
        content.body = "Your creation for \"\(prompt.prefix(50))\" has been saved to your gallery."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "generation_complete_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    func cancelDailyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["daily_generations"])
    }
}
