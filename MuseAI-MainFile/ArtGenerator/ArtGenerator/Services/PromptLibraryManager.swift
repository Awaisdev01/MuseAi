import Foundation

struct PromptTemplate: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var prompt: String
    var negativePrompt: String
    var tags: [String]
    var styleName: String
    let createdAt: Date
    var usageCount: Int

    init(title: String, prompt: String, negativePrompt: String = "", tags: [String] = [], styleName: String = "None", createdAt: Date = Date(), usageCount: Int = 0) {
        self.id = UUID()
        self.title = title
        self.prompt = prompt
        self.negativePrompt = negativePrompt
        self.tags = tags
        self.styleName = styleName
        self.createdAt = createdAt
        self.usageCount = usageCount
    }
}

@MainActor
class PromptLibraryManager: ObservableObject {
    static let shared = PromptLibraryManager()

    @Published var prompts: [PromptTemplate] = []

    private let fileName = "prompt_library.json"

    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    init() {
        load()
        if prompts.isEmpty { seedDefaults() }
    }

    func save(_ template: PromptTemplate) {
        if let index = prompts.firstIndex(where: { $0.id == template.id }) {
            prompts[index] = template
        } else {
            prompts.insert(template, at: 0)
        }
        persist()
    }

    func delete(_ template: PromptTemplate) {
        prompts.removeAll { $0.id == template.id }
        persist()
    }

    func incrementUsage(_ template: PromptTemplate) {
        guard let index = prompts.firstIndex(where: { $0.id == template.id }) else { return }
        prompts[index].usageCount += 1
        persist()
    }

    func search(query: String) -> [PromptTemplate] {
        guard !query.isEmpty else { return prompts }
        let q = query.lowercased()
        return prompts.filter {
            $0.title.lowercased().contains(q) ||
            $0.prompt.lowercased().contains(q) ||
            $0.tags.contains(where: { $0.lowercased().contains(q) })
        }
    }

    var allTags: [String] {
        Array(Set(prompts.flatMap(\.tags))).sorted()
    }

    func prompts(withTag tag: String) -> [PromptTemplate] {
        prompts.filter { $0.tags.contains(tag) }
    }

    var mostUsed: [PromptTemplate] {
        prompts.sorted { $0.usageCount > $1.usageCount }.prefix(10).map { $0 }
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(prompts) else { return }
        try? data.write(to: fileURL)
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        prompts = (try? decoder.decode([PromptTemplate].self, from: data)) ?? []
    }

    private func seedDefaults() {
        let defaults: [PromptTemplate] = [
            .init(title: "Dreamy Landscape", prompt: "Ethereal mountain landscape at golden hour with mist rolling through valleys, dreamy atmosphere, soft warm lighting", tags: ["landscape", "nature", "dreamy"]),
            .init(title: "Cyberpunk City", prompt: "Futuristic cyberpunk city at night with neon lights, rain-soaked streets, flying cars, holographic billboards", tags: ["sci-fi", "city", "cyberpunk"]),
            .init(title: "Portrait Studio", prompt: "Professional studio portrait with dramatic lighting, shallow depth of field, clean background", tags: ["portrait", "studio"]),
            .init(title: "Fantasy Creature", prompt: "Majestic mythical creature in an enchanted forest, bioluminescent details, magical particles, epic composition", tags: ["fantasy", "creature"]),
            .init(title: "Cozy Interior", prompt: "Warm cozy living room with fireplace, bookshelves, soft ambient lighting, rainy window, hygge atmosphere", tags: ["interior", "cozy"]),
            .init(title: "Food Photography", prompt: "Gourmet dish on elegant plate, professional food photography, soft directional lighting, bokeh background", tags: ["food", "photography"]),
            .init(title: "Abstract Art", prompt: "Abstract fluid art with vibrant colors, metallic swirls, high contrast, dynamic composition", tags: ["abstract", "colorful"]),
            .init(title: "Vintage Poster", prompt: "Retro vintage travel poster style, bold typography, limited color palette, art deco elements", tags: ["vintage", "poster", "retro"]),
        ]
        prompts = defaults
        persist()
    }
}
