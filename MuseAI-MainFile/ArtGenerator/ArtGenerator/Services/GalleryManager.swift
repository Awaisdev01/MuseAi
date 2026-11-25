import UIKit
import Photos
import SwiftUI
import Foundation

struct GeneratedArt: Identifiable, Codable, Equatable {
    let id: UUID
    let prompt: String
    let enhancedPrompt: String?
    let styleName: String
    let modelUsed: String
    let imageSize: String
    let createdAt: Date
    let isFavorite: Bool
    let collectionID: UUID?

    var imageFileName: String { "\(id.uuidString).jpg" }

    static func == (lhs: GeneratedArt, rhs: GeneratedArt) -> Bool { lhs.id == rhs.id }

    func withFavorite(_ value: Bool) -> GeneratedArt {
        GeneratedArt(id: id, prompt: prompt, enhancedPrompt: enhancedPrompt, styleName: styleName,
                     modelUsed: modelUsed, imageSize: imageSize, createdAt: createdAt, isFavorite: value, collectionID: collectionID)
    }

    func withCollection(_ cid: UUID?) -> GeneratedArt {
        GeneratedArt(id: id, prompt: prompt, enhancedPrompt: enhancedPrompt, styleName: styleName,
                     modelUsed: modelUsed, imageSize: imageSize, createdAt: createdAt, isFavorite: isFavorite, collectionID: cid)
    }
}

struct ArtCollection: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var emoji: String
    let createdAt: Date
}

@MainActor
class GalleryManager: ObservableObject {
    static let shared = GalleryManager()

    @Published var artworks: [GeneratedArt] = []
    @Published var favoriteArtworks: [GeneratedArt] = []
    @Published var collections: [ArtCollection] = []

    private let fm = FileManager.default
    private let imageCache = NSCache<NSString, UIImage>()

    private lazy var galleryDir: URL = {
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Gallery", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) { try? fm.createDirectory(at: dir, withIntermediateDirectories: true) }
        return dir
    }()

    private var metadataURL: URL { galleryDir.appendingPathComponent("gallery.json") }
    private var collectionsURL: URL { galleryDir.appendingPathComponent("collections.json") }

    init() {
        imageCache.countLimit = 50
        loadMetadata()
        loadCollections()
    }

    // MARK: - Save
    func saveArt(image: UIImage, prompt: String, enhancedPrompt: String?, style: ArtStylePreset, settings: GenerationSettings, collectionID: UUID? = nil) {
        let art = GeneratedArt(
            id: UUID(), prompt: prompt, enhancedPrompt: enhancedPrompt, styleName: style.name,
            modelUsed: settings.model.displayName, imageSize: settings.size.displayName,
            createdAt: Date(), isFavorite: false, collectionID: collectionID
        )
        let url = galleryDir.appendingPathComponent(art.imageFileName)
        if let data = image.jpegData(compressionQuality: 0.9) { try? data.write(to: url) }
        imageCache.setObject(image, forKey: art.id.uuidString as NSString)
        artworks.insert(art, at: 0)
        updateFavorites()
        saveMetadata()
    }

    func saveBatchArt(images: [UIImage], prompt: String, enhancedPrompt: String?, style: ArtStylePreset, settings: GenerationSettings) {
        for img in images { saveArt(image: img, prompt: prompt, enhancedPrompt: enhancedPrompt, style: style, settings: settings) }
    }

    // MARK: - Load (with cache)
    func loadImage(for art: GeneratedArt) -> UIImage? {
        let key = art.id.uuidString as NSString
        if let cached = imageCache.object(forKey: key) { return cached }
        let url = galleryDir.appendingPathComponent(art.imageFileName)
        guard let data = try? Data(contentsOf: url), let img = UIImage(data: data) else { return nil }
        imageCache.setObject(img, forKey: key)
        return img
    }

    // MARK: - Modify
    func toggleFavorite(_ art: GeneratedArt) {
        guard let i = artworks.firstIndex(where: { $0.id == art.id }) else { return }
        artworks[i] = art.withFavorite(!art.isFavorite)
        updateFavorites(); saveMetadata()
    }

    func moveToCollection(_ art: GeneratedArt, collectionID: UUID?) {
        guard let i = artworks.firstIndex(where: { $0.id == art.id }) else { return }
        artworks[i] = art.withCollection(collectionID)
        saveMetadata()
    }

    func deleteArt(_ art: GeneratedArt) {
        artworks.removeAll { $0.id == art.id }
        imageCache.removeObject(forKey: art.id.uuidString as NSString)
        try? fm.removeItem(at: galleryDir.appendingPathComponent(art.imageFileName))
        updateFavorites(); saveMetadata()
    }

    func saveUpscaledImage(_ image: UIImage, originalArt: GeneratedArt) {
        saveArt(image: image, prompt: originalArt.prompt + " (Upscaled)", enhancedPrompt: originalArt.enhancedPrompt,
                style: .none, settings: GenerationSettings(), collectionID: originalArt.collectionID)
    }

    // MARK: - Photo Library (non-deprecated)
    func saveToPhotoLibrary(image: UIImage) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else { return }
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
        }
    }

    // MARK: - Search
    func search(query: String) -> [GeneratedArt] {
        let q = query.lowercased()
        return artworks.filter { $0.prompt.lowercased().contains(q) || $0.styleName.lowercased().contains(q) }
    }

    // MARK: - Collections
    func artworks(in col: ArtCollection) -> [GeneratedArt] { artworks.filter { $0.collectionID == col.id } }

    func createCollection(name: String, emoji: String) {
        collections.append(ArtCollection(id: UUID(), name: name, emoji: emoji, createdAt: Date()))
        saveCollections()
    }

    func deleteCollection(_ col: ArtCollection) {
        for i in artworks.indices where artworks[i].collectionID == col.id { artworks[i] = artworks[i].withCollection(nil) }
        collections.removeAll { $0.id == col.id }
        saveCollections(); saveMetadata()
    }

    var totalGenerationCount: Int { artworks.count }

    // MARK: - Persistence
    private static let encoder: JSONEncoder = { let e = JSONEncoder(); e.dateEncodingStrategy = .iso8601; return e }()
    private static let decoder: JSONDecoder = { let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601; return d }()

    private func updateFavorites() { favoriteArtworks = artworks.filter(\.isFavorite) }

    private func saveMetadata() { if let d = try? Self.encoder.encode(artworks) { try? d.write(to: metadataURL) } }
    private func loadMetadata() {
        guard let d = try? Data(contentsOf: metadataURL), let a = try? Self.decoder.decode([GeneratedArt].self, from: d) else { return }
        artworks = a; updateFavorites()
    }
    private func saveCollections() { if let d = try? Self.encoder.encode(collections) { try? d.write(to: collectionsURL) } }
    private func loadCollections() {
        guard let d = try? Data(contentsOf: collectionsURL), let c = try? Self.decoder.decode([ArtCollection].self, from: d) else { return }
        collections = c
    }
}
