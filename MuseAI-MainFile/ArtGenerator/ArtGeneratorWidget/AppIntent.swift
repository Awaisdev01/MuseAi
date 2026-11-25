import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Muse AI Inspiration" }
    static var description: IntentDescription { "Get daily Muse AI prompt inspiration." }
}
