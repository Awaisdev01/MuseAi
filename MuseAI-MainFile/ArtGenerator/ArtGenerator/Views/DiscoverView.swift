import SwiftUI

struct FeaturedPrompt: Identifiable {
    let id = UUID()
    let title: String
    let prompt: String
    let styleName: String
    let category: String
    let author: String
}

struct DiscoverView: View {

    @EnvironmentObject var manager: DataManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory = "All"
    @StateObject private var queue = GenerationQueue.shared

    private let categories = ["All", "Trending", "Landscapes", "Characters", "Abstract", "Sci-Fi", "Fantasy", "Photo"]

    private var filteredPrompts: [FeaturedPrompt] {
        if selectedCategory == "All" || selectedCategory == "Trending" {
            return featuredPrompts
        }
        return featuredPrompts.filter { $0.category == selectedCategory }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        if queue.pendingCount > 0 || queue.isProcessing {
                            QueueStatusBar
                        }
                        CategoryBar
                        StaffPicksSection
                        PromptGrid
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Queue Status
    private var QueueStatusBar: some View {
        HStack(spacing: 12) {
            if queue.isProcessing {
                ProgressView().scaleEffect(0.8).tint(DS.Colors.accent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Generation Queue")
                    .font(.caption.weight(.semibold)).foregroundColor(Color(.label))
                Text("\(queue.pendingCount) pending · \(queue.completedCount) completed")
                    .font(.caption2).foregroundColor(.secondary)
            }
            Spacer()
            Button("Clear") {
                HapticManager.tap()
                queue.removeCompleted()
            }
            .font(.caption.weight(.medium))
            .foregroundColor(.purple)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(DS.Colors.accent.opacity(0.1)))
        .padding(.horizontal, 16)
    }

    // MARK: - Categories
    private var CategoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { cat in
                    Button {
                        HapticManager.selectionChanged()
                        withAnimation { selectedCategory = cat }
                    } label: {
                        Text(cat)
                            .font(.caption.weight(.medium))
                            .foregroundColor(selectedCategory == cat ? .white : .secondary)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(
                                Capsule().fill(selectedCategory == cat ? DS.Colors.accent.opacity(0.3) : Color(.tertiarySystemBackground))
                                    .overlay(Capsule().strokeBorder(selectedCategory == cat ? DS.Colors.accent.opacity(0.5) : Color.clear, lineWidth: 1))
                            )
                    }.buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Staff Picks
    private var StaffPicksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill").font(.caption).foregroundColor(.yellow)
                Text("Staff Picks").font(.headline).foregroundColor(Color(.label))
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(featuredPrompts.prefix(5)) { item in
                        StaffPickCard(item: item) {
                            HapticManager.impact()
                            manager.promptText = item.prompt
                            dismiss()
                        } onQueue: {
                            queue.enqueue(
                                prompt: item.prompt,
                                style: ArtStylePreset.allStyles.first(where: { $0.name == item.styleName }) ?? .none,
                                settings: GenerationSettings()
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Grid
    private var PromptGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Community Prompts")
                .font(.headline).foregroundColor(Color(.label))
                .padding(.horizontal, 16)

            LazyVStack(spacing: 12) {
                ForEach(filteredPrompts) { item in
                    CommunityPromptCard(item: item) {
                        HapticManager.impact()
                        manager.promptText = item.prompt
                        dismiss()
                    } onQueue: {
                        queue.enqueue(
                            prompt: item.prompt,
                            style: ArtStylePreset.allStyles.first(where: { $0.name == item.styleName }) ?? .none,
                            settings: GenerationSettings()
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Data
    private let featuredPrompts: [FeaturedPrompt] = [
        .init(title: "Celestial Garden", prompt: "A floating garden in space with bioluminescent flowers, nebula in the background, crystal pathways, ethereal lighting, dreamlike atmosphere, 8k", styleName: "Fantasy", category: "Fantasy", author: "ArtBot"),
        .init(title: "Neon Samurai", prompt: "Cyberpunk samurai standing in a neon-lit Tokyo alley, rain reflections, holographic katana, dramatic composition, cinematic lighting", styleName: "Cinematic", category: "Characters", author: "PixelDreamer"),
        .init(title: "Ocean Depths", prompt: "Deep sea underwater scene with ancient ruins covered in coral, rays of light from above, schools of tropical fish, volumetric god rays", styleName: "Photorealistic", category: "Landscapes", author: "DeepBlue"),
        .init(title: "Abstract Emotion", prompt: "Abstract representation of joy, fluid swirling colors of gold and coral, dynamic energy, textured canvas feel, gallery quality", styleName: "Digital Art", category: "Abstract", author: "ChromaFlow"),
        .init(title: "Steampunk Library", prompt: "Grand steampunk library with brass gears, leather books, warm gas lamp lighting, Victorian architecture, intricate mechanical details", styleName: "3D Render", category: "Sci-Fi", author: "GearMaster"),
        .init(title: "Mountain Dawn", prompt: "First light hitting snow-capped mountain peaks, alpine meadow with wildflowers, crystal clear lake reflection, golden hour photography", styleName: "Photorealistic", category: "Landscapes", author: "NatureEye"),
        .init(title: "Magical Fox", prompt: "Arctic fox made of northern lights and stardust, magical forest clearing, glowing particles, ethereal and whimsical, children's book illustration", styleName: "Fantasy", category: "Fantasy", author: "StoryWeaver"),
        .init(title: "Urban Sketch", prompt: "Loose watercolor sketch of a bustling European cafe scene, warm afternoon light, people sitting at outdoor tables, artistic and impressionistic", styleName: "Watercolor", category: "Photo", author: "SketchDaily"),
        .init(title: "Mech Warrior", prompt: "Giant mech robot in a post-apocalyptic desert, sand storm, weathered battle armor, dramatic low angle, cinematic composition", styleName: "Cinematic", category: "Sci-Fi", author: "MechForge"),
        .init(title: "Zen Garden", prompt: "Minimalist Japanese zen garden at dawn, raked sand patterns, single cherry blossom tree, morning mist, peaceful and serene", styleName: "Minimalist", category: "Landscapes", author: "ZenMind"),
        .init(title: "Pixel Kingdom", prompt: "16-bit pixel art medieval kingdom with castle, dragons, knights, vibrant retro colors, detailed sprite work, nostalgic gaming aesthetic", styleName: "Pixel Art", category: "Fantasy", author: "RetroPixel"),
        .init(title: "Future City", prompt: "Solarpunk utopian city with vertical gardens, clean energy, flying vehicles, lush greenery integrated into architecture, optimistic future", styleName: "3D Render", category: "Sci-Fi", author: "GreenFuture"),
    ]
}

// MARK: - Staff Pick Card
private struct StaffPickCard: View {
    let item: FeaturedPrompt
    let onUse: () -> Void
    let onQueue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                LinearGradient(colors: [.purple.opacity(0.3), .blue.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                VStack {
                    Image(systemName: "sparkles").font(.largeTitle).foregroundColor(.white.opacity(0.3))
                }
            }
            .frame(width: 200, height: 130)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(item.title).font(.subheadline.weight(.semibold)).foregroundColor(Color(.label))
            Text(item.prompt).font(.caption2).foregroundColor(.secondary).lineLimit(2)

            HStack(spacing: 8) {
                Button("Use", action: onUse)
                    .font(.caption.weight(.semibold)).foregroundColor(.purple)
                Button { onQueue() } label: {
                    Image(systemName: "plus.circle")
                        .font(.caption).foregroundColor(.secondary)
                }
                .accessibilityLabel("Add to generation queue")
            }
        }
        .frame(width: 200)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Community Card
private struct CommunityPromptCard: View {
    let item: FeaturedPrompt
    let onUse: () -> Void
    let onQueue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title).font(.subheadline.weight(.semibold)).foregroundColor(Color(.label))
                    Text("by \(item.author)").font(.caption2).foregroundColor(.secondary)
                }
                Spacer()
                Text(item.styleName)
                    .font(.caption2.weight(.medium))
                    .foregroundColor(.purple)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill(DS.Colors.accent.opacity(0.15)))
            }

            Text(item.prompt).font(.caption).foregroundColor(.white.opacity(0.7)).lineLimit(3)

            HStack(spacing: 12) {
                Spacer()
                Button { onQueue() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "list.badge.plus")
                        Text("Queue")
                    }.font(.caption.weight(.medium)).foregroundColor(.secondary)
                }
                Button("Use Prompt", action: onUse)
                    .font(.caption.weight(.semibold)).foregroundColor(.purple)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(.tertiarySystemBackground)))
        .accessibilityElement(children: .contain)
    }
}
