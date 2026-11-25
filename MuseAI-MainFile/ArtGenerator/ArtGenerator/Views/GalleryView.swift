import SwiftUI

enum GalleryFilter: Equatable {
    case all, favorites, collection(ArtCollection)

    static func == (lhs: GalleryFilter, rhs: GalleryFilter) -> Bool {
        switch (lhs, rhs) {
        case (.all, .all): return true
        case (.favorites, .favorites): return true
        case (.collection(let a), .collection(let b)): return a.id == b.id
        default: return false
        }
    }
}

struct GalleryView: View {

    @EnvironmentObject var manager: DataManager
    @State private var selectedArt: GeneratedArt?
    @State private var filter: GalleryFilter = .all
    @State private var searchText = ""
    @State private var showNewCollection = false
    @State private var newCollectionName = ""
    @State private var newCollectionEmoji = "🎨"

    private var displayedArtworks: [GeneratedArt] {
        var results: [GeneratedArt]
        switch filter {
        case .all:
            results = manager.gallery.artworks
        case .favorites:
            results = manager.gallery.favoriteArtworks
        case .collection(let col):
            results = manager.gallery.artworks(in: col)
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            results = results.filter {
                $0.prompt.lowercased().contains(query) ||
                $0.styleName.lowercased().contains(query) ||
                ($0.enhancedPrompt?.lowercased().contains(query) ?? false)
            }
        }

        return results
    }

    private let columns = [
        GridItem(.flexible(), spacing: 3),
        GridItem(.flexible(), spacing: 3),
        GridItem(.flexible(), spacing: 3)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    if !manager.gallery.artworks.isEmpty {
                        FilterBar
                    }

                    if displayedArtworks.isEmpty {
                        Spacer()
                        EmptyGalleryContent
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            GalleryStatsBar
                            PhotoGrid
                            Spacer(minLength: 100)
                        }
                        .refreshable {
                            HapticManager.tap()
                            try? await Task.sleep(nanoseconds: 300_000_000)
                        }
                    }
                }
            }
            .navigationTitle(navTitle)
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search prompts, styles...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button { withAnimation { filter = .all } } label: {
                            Label("All", systemImage: "photo.stack")
                        }
                        Button { withAnimation { filter = .favorites } } label: {
                            Label("Favorites", systemImage: "heart")
                        }
                        if !manager.gallery.collections.isEmpty {
                            Divider()
                            ForEach(manager.gallery.collections) { col in
                                Button {
                                    withAnimation { filter = .collection(col) }
                                } label: {
                                    Label("\(col.emoji) \(col.name)", systemImage: "folder")
                                }
                            }
                        }
                        Divider()
                        Button { showNewCollection = true } label: {
                            Label("New Collection", systemImage: "folder.badge.plus")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Filter gallery")
                }
            }
            .sheet(item: $selectedArt) { art in
                ImageDetailView(art: art).environmentObject(manager)
            }
            .alert("New Collection", isPresented: $showNewCollection) {
                TextField("Name", text: $newCollectionName)
                Button("Create") {
                    guard !newCollectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    manager.gallery.createCollection(name: newCollectionName, emoji: newCollectionEmoji)
                    manager.achievements.refresh(gallery: manager.gallery, streak: manager.streak)
                    newCollectionName = ""
                    HapticManager.success()
                }
                Button("Cancel", role: .cancel) { newCollectionName = "" }
            } message: {
                Text("Enter a name for your collection.")
            }
        }
    }

    private var navTitle: String {
        switch filter {
        case .all: return "Gallery"
        case .favorites: return "Favorites"
        case .collection(let col): return "\(col.emoji) \(col.name)"
        }
    }

    // MARK: - Filter Bar
    private var FilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "All", isActive: filter == .all) {
                    HapticManager.selectionChanged()
                    withAnimation { filter = .all }
                }
                FilterChip(label: "♥ Favorites", isActive: filter == .favorites) {
                    HapticManager.selectionChanged()
                    withAnimation { filter = .favorites }
                }
                ForEach(manager.gallery.collections) { col in
                    FilterChip(label: "\(col.emoji) \(col.name)", isActive: filter == .collection(col)) {
                        HapticManager.selectionChanged()
                        withAnimation { filter = .collection(col) }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Stats
    private var GalleryStatsBar: some View {
        HStack(spacing: 20) {
            StatBadge(value: "\(manager.gallery.artworks.count)", label: "Created")
            StatBadge(value: "\(manager.gallery.favoriteArtworks.count)", label: "Favorites")
            StatBadge(value: "\(manager.gallery.collections.count)", label: "Collections")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(manager.gallery.artworks.count) creations, \(manager.gallery.favoriteArtworks.count) favorites, \(manager.gallery.collections.count) collections")
    }

    // MARK: - Grid
    private var PhotoGrid: some View {
        LazyVGrid(columns: columns, spacing: 3) {
            ForEach(displayedArtworks) { art in
                GalleryThumbnail(art: art) {
                    HapticManager.tap()
                    selectedArt = art
                }
            }
        }
        .padding(.horizontal, 3)
    }

    // MARK: - Empty
    private var EmptyGalleryContent: some View {
        VStack(spacing: 16) {
            let isFav = filter == .favorites
            let isSearch = !searchText.isEmpty
            Image(systemName: isSearch ? "magnifyingglass" : (isFav ? "heart.slash" : "photo.on.rectangle.angled"))
                .font(.system(size: 50, weight: .light))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(isSearch ? "No Results" : (isFav ? "No Favorites Yet" : "No Creations Yet"))
                .font(.title3.bold())
                .foregroundColor(Color(.label))

            Text(isSearch ? "Try a different search term." :
                    (isFav ? "Tap the heart on any creation to add it here." :
                        "Your AI masterpieces will appear here.\nHead to Create to make your first one!"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Filter Chip
private struct FilterChip: View {
    let label: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundColor(isActive ? .white : .secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isActive ? DS.Colors.accent.opacity(0.3) : Color.white.opacity(0.06))
                        .overlay(
                            Capsule().strokeBorder(isActive ? DS.Colors.accent.opacity(0.5) : Color.clear, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

// MARK: - Thumbnail
private struct GalleryThumbnail: View {
    let art: GeneratedArt
    let onTap: () -> Void

    @StateObject private var gallery = GalleryManager.shared

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Color.white.opacity(0.05)
                if let image = gallery.loadImage(for: art) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .overlay(alignment: .topTrailing) {
                if art.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.caption).foregroundColor(.pink)
                        .padding(6).accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Artwork: \(art.prompt)")
        .accessibilityAddTraits(.isImage)
    }
}

// MARK: - Stat Badge
private struct StatBadge: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Color(.label))
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(0.06))
        )
    }
}

#Preview {
    GalleryView().environmentObject(DataManager())
}
