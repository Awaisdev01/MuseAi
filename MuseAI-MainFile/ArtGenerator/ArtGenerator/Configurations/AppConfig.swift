import SwiftUI
import Foundation

class AppConfig {

    // MARK: - Brand
    static let appName = "Muse AI"
    static let appTagline = "Imagine. Create. Share."
    static let appVersion = "2.1"

    // MARK: - OpenAI
    // Buyers must use their own paid OpenAI API account and credits.
    // Paste your key from platform.openai.com/api-keys. Never commit a real key to source control.
    static let apiKey: String = "YOUR_OPENAI_API_KEY"

    /// True once a real key has been pasted in above.
    static var isAPIKeyConfigured: Bool {
        !apiKey.isEmpty && !apiKey.contains("YOUR_") && !apiKey.contains("xxxx")
    }

    // MARK: - API Routing
    // Default talks to OpenAI directly (simplest setup). For production apps, point this at your
    // own backend proxy instead so the real API key never ships inside the app binary — set
    // `useBackendProxy = true` and `backendProxyBaseURL` to your server, and forward requests from
    // there to OpenAI using the key stored server-side. OpenAIService reads these automatically.
    static let useBackendProxy: Bool = false
    static let backendProxyBaseURL: String = "https://your-backend.example.com/v1"
    static var apiBaseURL: String { useBackendProxy ? backendProxyBaseURL : "https://api.openai.com/v1" }

    // MARK: - Free Tier
    static let freeGenerationsPerDay: Int = 5
    static let freeStyleCount: Int = 3

    // MARK: - Smart Paywall Triggers
    static let paywallAfterGenerations: Int = 3
    static let paywallAfterDays: Int = 2

    // MARK: - Settings
    static let emailSupport = "support@yourapp.com"
    static let privacyURL = URL(string: "https://yourapp.com/privacy")!
    static let termsAndConditionsURL = URL(string: "https://yourapp.com/terms")!
    static let appStoreURL = URL(string: "https://apps.apple.com/app/idXXXXXXXXX")!

    // MARK: - Product IDs
    static let monthlyProductID = SubscriptionTier.monthly.rawValue
    static let yearlyProductID = SubscriptionTier.yearly.rawValue
    static let lifetimeProductID = SubscriptionTier.lifetime.rawValue

    // MARK: - Keys
    static let hasSeenOnboardingKey = "hasSeenOnboarding"

    // MARK: - Inspiration Assets
    static let inspirationAssets: [AssetModel] = [
        .init(imageName: "princess-one", imageText: "Macro closeup headshot of a beautiful happy magical fairy princess wearing a white robe and flowers in her hair in a fantasy garden, intricate, rim light, god rays, volumetric lighting, elegant, highly detailed, digital painting, concept art, smooth, sharp focus", isHorizontal: true, category: "Featured"),
        .init(imageName: "princess-two", imageText: "Ultra realistic photo, princess in the mushroom kingdom, beautiful face, intricate, highly detailed, smooth, sharp focus", isHorizontal: true, category: "Featured"),
        .init(imageName: "another-world", imageText: "Another world, tropical style, extreme detail, view from planet, landscape, high detail graphics, cinematic, 8k, vivid, vibrant colors, cinematic lighting", isHorizontal: true, category: "Featured"),
        .init(imageName: "pyramids", imageText: "Pyramids of Giza at sunset, abstract geometric art style, golden light, dramatic shadows", isHorizontal: true, category: "Featured"),
        .init(imageName: "santa", imageText: "Santa Claus eating Christmas cookies and milk, warm cozy lighting, festive atmosphere", isHorizontal: false, category: "Characters"),
        .init(imageName: "cat", imageText: "Kneeling cat knight in finely detailed armor, portrait, intricate silver design, cinematic lighting, 4k", isHorizontal: false, category: "Characters"),
        .init(imageName: "dead", imageText: "Day of the dead portrait, intricate, elegant, highly detailed, digital painting, concept art, smooth, sharp focus, symmetrical", isHorizontal: false, category: "Characters"),
        .init(imageName: "superheroes", imageText: "All superheroes assembled in New York City, epic cinematic composition, dramatic lighting", isHorizontal: false, category: "Characters"),
        .init(imageName: "coral", imageText: "Coral reef phoenix at night with a sky full of stars, intricate, elegant, highly detailed, volumetric lighting, epic composition, 8k", isHorizontal: false, category: "Landscapes"),
        .init(imageName: "turtle", imageText: "Giant turtle with a village built into its shell, fishing boats in the distance, waterfalls, concept art, warm lighting, volumetric", isHorizontal: false, category: "Landscapes"),
        .init(imageName: "ancient", imageText: "Half buried ruins of an ancient lost civilization at sunset, shadows, epic composition, volumetric lighting, highly detailed", isHorizontal: false, category: "Landscapes"),
        .init(imageName: "forest", imageText: "Enchanted forest with a path between trees, sun shining through, cinematic lighting, ultra realistic, 8k, magical atmosphere", isHorizontal: false, category: "Landscapes"),
        .init(imageName: "sunset", imageText: "Sunset in the mountains, golden hour, dramatic clouds, panoramic landscape, breathtaking view", isHorizontal: false, category: "Landscapes"),
        .init(imageName: "puppy", imageText: "Adorable puppy wearing tiny glasses reading a book, soft lighting, detailed fur, heartwarming", isHorizontal: false, category: "Animals"),
        .init(imageName: "dragon", imageText: "Majestic dragon flying over a medieval castle, fire breath, dramatic sky, epic fantasy", isHorizontal: false, category: "Animals"),
        .init(imageName: "kitten", imageText: "Cute Ragdoll kitten in an adventure scene, detailed, dynamic lighting, warm colors, vivid, beautiful", isHorizontal: false, category: "Animals"),
        .init(imageName: "Raccoon", imageText: "Raccoon in a winter wonderland, snow falling, cozy scene, warm lighting, detailed fur", isHorizontal: false, category: "Animals")
    ]
}

// MARK: - Tab Bar
enum AppTab: String, CaseIterable, Identifiable {
    case home = "sparkles"
    case create = "wand.and.stars"
    case gallery = "photo.on.rectangle.angled"
    case settings = "gearshape"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Explore"
        case .create: return "Create"
        case .gallery: return "Gallery"
        case .settings: return "Settings"
        }
    }

    var filledIcon: String {
        switch self {
        case .home: return "sparkles"
        case .create: return "wand.and.stars"
        case .gallery: return "photo.on.rectangle.angled"
        case .settings: return "gearshape.fill"
        }
    }
}

// All colors/gradients in DesignSystem.swift — use DS.Colors.* and DS.Gradients.*
