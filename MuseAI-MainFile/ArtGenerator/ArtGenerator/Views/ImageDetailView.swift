import SwiftUI

struct ImageDetailView: View {

    let art: GeneratedArt
    @EnvironmentObject var manager: DataManager
    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage?
    @State private var showShareSheet = false
    @State private var showDeleteConfirm = false
    @State private var showUpscaler = false
    @State private var showCollectionPicker = false
    @State private var showCanvasEditor = false
    @State private var showExport = false
    @State private var savedToPhotos = false
    @State private var isUpscaling = false
    @State private var upscaleLevel: UpscaleLevel = .x2

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        ImageSection
                        InfoSection
                        PrimaryActions
                        SecondaryActions
                        if manager.isPremium { UpscaleSection }
                        CollectionSection
                        DeleteButton
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }

                if isUpscaling { UpscalingOverlay }
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { HapticManager.tap(); dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticManager.impact()
                        manager.gallery.toggleFavorite(art)
                        manager.achievements.refresh(gallery: manager.gallery, streak: manager.streak)
                    } label: {
                        Image(systemName: currentArt.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(currentArt.isFavorite ? .pink : .secondary)
                    }
                    .accessibilityLabel(currentArt.isFavorite ? "Remove from favorites" : "Add to favorites")
                }
            }
            .alert("Delete Creation?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    HapticManager.heavyImpact()
                    manager.gallery.deleteArt(art)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: { Text("This cannot be undone.") }
            .sheet(isPresented: $showShareSheet) {
                if let image { ShareSheet(items: [image]) }
            }
            .fullScreenCover(isPresented: $showCanvasEditor) {
                if let img = image {
                    CanvasEditorView(originalImage: img) { edited in
                        image = edited
                        manager.gallery.saveUpscaledImage(edited, originalArt: art)
                    }
                }
            }
            .sheet(isPresented: $showExport) {
                if let img = image {
                    ExportView(image: img, prompt: art.prompt)
                }
            }
            .onAppear { image = manager.gallery.loadImage(for: art) }
        }
    }

    private var currentArt: GeneratedArt {
        manager.gallery.artworks.first(where: { $0.id == art.id }) ?? art
    }

    private var ImageSection: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable().aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .accessibilityLabel("Generated image").accessibilityAddTraits(.isImage)
            } else {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.tertiarySystemBackground)).aspectRatio(1, contentMode: .fit)
                    .overlay(ProgressView().tint(.white))
            }
        }
    }

    private var InfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            InfoRow(label: "Prompt", value: art.prompt)
            if let enhanced = art.enhancedPrompt, enhanced != art.prompt {
                InfoRow(label: "Enhanced Prompt", value: enhanced)
            }
            HStack(spacing: 12) {
                InfoChip(icon: "paintbrush.fill", text: art.styleName)
                InfoChip(icon: "square.resize", text: art.imageSize)
                InfoChip(icon: "cpu", text: art.modelUsed)
            }
            if let img = image {
                InfoChip(icon: "arrow.up.left.and.arrow.down.right", text: ImageUpscaler.resolution(of: img))
            }
            Text(art.createdAt, style: .date).font(.caption).foregroundColor(.secondary)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(.tertiarySystemBackground)))
    }

    // MARK: - Primary Actions
    private var PrimaryActions: some View {
        HStack(spacing: 12) {
            ActionButton(icon: "square.and.arrow.down", label: savedToPhotos ? "Saved!" : "Save") {
                guard let image else { return }
                manager.gallery.saveToPhotoLibrary(image: image)
                HapticManager.success()
                withAnimation { savedToPhotos = true }
            }
            ActionButton(icon: "square.and.arrow.up", label: "Share") {
                HapticManager.tap(); showShareSheet = true
            }
            ActionButton(icon: "square.and.arrow.up.trianglebadge.exclamationmark", label: "Export") {
                HapticManager.tap(); showExport = true
            }
        }
    }

    // MARK: - Secondary Actions
    private var SecondaryActions: some View {
        HStack(spacing: 12) {
            ActionButton(icon: "paintbrush", label: "Edit") {
                HapticManager.tap(); showCanvasEditor = true
            }
            ActionButton(icon: "doc.on.doc", label: "Copy") {
                UIPasteboard.general.string = art.prompt
                HapticManager.success()
            }
            ActionButton(icon: "arrow.counterclockwise", label: "Recreate") {
                HapticManager.tap()
                manager.promptText = art.prompt
                dismiss()
            }
        }
    }

    // MARK: - Upscale
    private var UpscaleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.up.circle.fill").foregroundStyle(DS.Gradients.accent)
                Text("Upscale Image").font(.subheadline.weight(.semibold)).foregroundColor(Color(.label))
                Spacer()
            }

            HStack(spacing: 10) {
                ForEach(UpscaleLevel.allCases) { level in
                    Button {
                        HapticManager.selectionChanged(); upscaleLevel = level
                    } label: {
                        VStack(spacing: 4) {
                            Text(level.displayName).font(.subheadline.weight(.bold))
                            if let img = image {
                                Text(ImageUpscaler.estimatedResolution(of: img, at: level)).font(.caption2)
                            }
                        }
                        .foregroundColor(upscaleLevel == level ? .white : .secondary)
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(upscaleLevel == level ? DS.Colors.accent.opacity(0.3) : Color(.tertiarySystemBackground))
                                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(upscaleLevel == level ? DS.Colors.accent.opacity(0.5) : Color.clear, lineWidth: 1))
                        )
                    }.buttonStyle(.plain)
                }
            }

            Button { performUpscale() } label: {
                HStack(spacing: 8) {
                    Image(systemName: "wand.and.stars")
                    Text("Upscale to \(upscaleLevel.displayName)").font(.subheadline.weight(.semibold))
                }
                .foregroundColor(Color(.label)).frame(maxWidth: .infinity).frame(height: 44)
                .background(DS.Gradients.accent)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(.tertiarySystemBackground)))
    }

    // MARK: - Collection
    private var CollectionSection: some View {
        Group {
            if !manager.gallery.collections.isEmpty {
                Menu {
                    Button("Remove from collection") {
                        manager.gallery.moveToCollection(art, collectionID: nil); HapticManager.tap()
                    }
                    Divider()
                    ForEach(manager.gallery.collections) { col in
                        Button("\(col.emoji) \(col.name)") {
                            manager.gallery.moveToCollection(art, collectionID: col.id); HapticManager.success()
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "folder.badge.plus")
                        Text(collectionLabel).font(.subheadline.weight(.medium))
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down").font(.caption)
                    }
                    .foregroundColor(Color(.label))
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(.tertiarySystemBackground)))
                }
            }
        }
    }

    private var collectionLabel: String {
        if let colID = currentArt.collectionID,
           let col = manager.gallery.collections.first(where: { $0.id == colID }) {
            return "\(col.emoji) \(col.name)"
        }
        return "Add to Collection"
    }

    private var DeleteButton: some View {
        Button(role: .destructive) { HapticManager.warning(); showDeleteConfirm = true } label: {
            HStack { Image(systemName: "trash"); Text("Delete") }
                .font(.subheadline.weight(.medium)).foregroundColor(.red.opacity(0.8))
                .frame(maxWidth: .infinity).frame(height: 44)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.red.opacity(0.1)))
        }
    }

    private var UpscalingOverlay: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView().scaleEffect(1.3).tint(.white)
                Text("Upscaling to \(upscaleLevel.displayName)...").font(.subheadline.weight(.medium)).foregroundColor(Color(.label))
            }
            .padding(28)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.ultraThinMaterial))
        }
    }

    private func performUpscale() {
        guard let sourceImage = image else { return }
        isUpscaling = true; HapticManager.impact()
        DispatchQueue.global(qos: .userInitiated).async {
            let upscaled = ImageUpscaler.upscale(sourceImage, level: upscaleLevel)
            DispatchQueue.main.async {
                isUpscaling = false
                if let result = upscaled {
                    image = result
                    manager.gallery.saveUpscaledImage(result, originalArt: art)
                    HapticManager.success()
                } else { HapticManager.error() }
            }
        }
    }
}

// MARK: - Components
private struct InfoRow: View {
    let label: String; let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption.weight(.semibold)).foregroundColor(.secondary)
            Text(value).font(.subheadline).foregroundColor(Color(.label))
        }.accessibilityElement(children: .combine)
    }
}

private struct InfoChip: View {
    let icon: String; let text: String
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption2).accessibilityHidden(true)
            Text(text).font(.caption)
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Capsule().fill(Color(.tertiarySystemBackground)))
        .accessibilityElement(children: .combine)
    }
}

private struct ActionButton: View {
    let icon: String; let label: String; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 17))
                Text(label).font(.caption2.weight(.medium))
            }
            .foregroundColor(.white.opacity(0.8))
            .frame(maxWidth: .infinity).frame(height: 58)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(.tertiarySystemBackground)))
        }.buttonStyle(.plain).accessibilityLabel(label)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
