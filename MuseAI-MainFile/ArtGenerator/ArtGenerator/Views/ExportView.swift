import SwiftUI
import UniformTypeIdentifiers

enum ExportFormat: String, CaseIterable, Identifiable {
    case jpeg = "JPEG"
    case png = "PNG"
    case heic = "HEIC"

    var id: String { rawValue }
    var fileExtension: String { rawValue.lowercased() }

    var utType: UTType {
        switch self {
        case .jpeg: return .jpeg
        case .png: return .png
        case .heic: return .heic
        }
    }
}

struct ExportView: View {

    let image: UIImage
    let prompt: String
    @Environment(\.dismiss) private var dismiss
    @State private var format: ExportFormat = .jpeg
    @State private var quality: Double = 0.9
    @State private var includeWatermark = false
    @State private var scale: Double = 1.0
    @State private var isExporting = false

    private var estimatedSize: String {
        guard let data = imageData else { return "—" }
        let mb = Double(data.count) / (1024 * 1024)
        return mb >= 1 ? String(format: "%.1f MB", mb) : String(format: "%.0f KB", mb * 1024)
    }

    private var resolution: String {
        guard let cg = image.cgImage else { return "—" }
        let w = Int(Double(cg.width) * scale)
        let h = Int(Double(cg.height) * scale)
        return "\(w) × \(h)"
    }

    private var imageData: Data? {
        let scaled = scale != 1.0 ? scaleImage(image, by: scale) : image
        let final = includeWatermark ? addWatermark(to: scaled) : scaled

        switch format {
        case .jpeg:
            return final.jpegData(compressionQuality: quality)
        case .png:
            return final.pngData()
        case .heic:
            if let ciImage = CIImage(image: final) {
                let context = CIContext()
                return context.heifRepresentation(of: ciImage, format: .RGBA8, colorSpace: ciImage.colorSpace ?? CGColorSpaceCreateDeviceRGB())
            }
            return final.jpegData(compressionQuality: quality)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        PreviewSection
                        FormatSection
                        QualitySection
                        ScaleSection
                        WatermarkSection
                        InfoSection
                        ExportButton
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var PreviewSection: some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxHeight: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var FormatSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Format").font(.subheadline.weight(.semibold)).foregroundColor(.secondary)
            HStack(spacing: 10) {
                ForEach(ExportFormat.allCases) { fmt in
                    Button {
                        HapticManager.selectionChanged()
                        withAnimation { format = fmt }
                    } label: {
                        Text(fmt.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(format == fmt ? Color(.label) : .secondary)
                            .frame(maxWidth: .infinity).frame(height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(format == fmt ? DS.Colors.accent.opacity(0.3) : Color(.tertiarySystemBackground))
                                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(format == fmt ? DS.Colors.accent.opacity(0.5) : Color.clear, lineWidth: 1))
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(fmt.rawValue)
                    .accessibilityAddTraits(format == fmt ? .isSelected : [])
                }
            }
        }
    }

    private var QualitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Quality").font(.subheadline.weight(.semibold)).foregroundColor(.secondary)
                Spacer()
                Text("\(Int(quality * 100))%").font(.caption.weight(.medium)).foregroundColor(Color(.label))
            }
            Slider(value: $quality, in: 0.1...1.0, step: 0.05).tint(DS.Colors.accent)
        }
        .opacity(format == .png ? 0.4 : 1)
        .disabled(format == .png)
    }

    private var ScaleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Scale").font(.subheadline.weight(.semibold)).foregroundColor(.secondary)
                Spacer()
                Text("\(String(format: "%.1f", scale))x — \(resolution)").font(.caption.weight(.medium)).foregroundColor(Color(.label))
            }
            HStack(spacing: 10) {
                ForEach([0.5, 1.0, 1.5, 2.0], id: \.self) { s in
                    Button {
                        HapticManager.selectionChanged()
                        withAnimation { scale = s }
                    } label: {
                        Text("\(String(format: "%.1f", s))x")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(scale == s ? Color(.label) : .secondary)
                            .frame(maxWidth: .infinity).frame(height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(scale == s ? DS.Colors.accent.opacity(0.3) : Color(.tertiarySystemBackground))
                            )
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    private var WatermarkSection: some View {
        Toggle(isOn: $includeWatermark) {
            HStack(spacing: 10) {
                Image(systemName: "textformat.abc").foregroundColor(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Watermark").font(.subheadline).foregroundColor(Color(.label))
                    Text("Adds '\(AppConfig.appName)' text").font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .tint(DS.Colors.accent)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(.tertiarySystemBackground)))
    }

    private var InfoSection: some View {
        HStack {
            Label(estimatedSize, systemImage: "doc").font(.caption).foregroundColor(.secondary)
            Spacer()
            Label(format.fileExtension, systemImage: "photo").font(.caption).foregroundColor(.secondary)
        }
    }

    private var ExportButton: some View {
        Button {
            exportImage()
        } label: {
            HStack(spacing: 8) {
                if isExporting {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export \(format.rawValue)")
                }
            }
            .font(.headline).foregroundColor(Color(.label))
            .frame(maxWidth: .infinity).frame(height: 56)
            .background(DS.Gradients.accent)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(isExporting)
    }

    // MARK: - Processing
    private func scaleImage(_ image: UIImage, by factor: Double) -> UIImage {
        guard factor != 1.0, let cg = image.cgImage else { return image }
        let newSize = CGSize(width: Double(cg.width) * factor, height: Double(cg.height) * factor)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private func addWatermark(to image: UIImage) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { _ in
            image.draw(at: .zero)
            let text = AppConfig.appName
            let fontSize = max(image.size.width * 0.03, 14)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: fontSize, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.4)
            ]
            let size = (text as NSString).size(withAttributes: attrs)
            let point = CGPoint(x: image.size.width - size.width - 16, y: image.size.height - size.height - 16)
            (text as NSString).draw(at: point, withAttributes: attrs)
        }
    }

    private func exportImage() {
        guard let data = imageData else { return }
        isExporting = true
        HapticManager.impact()

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("export.\(format.fileExtension)")
        try? data.write(to: tempURL)

        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else {
            isExporting = false
            return
        }

        let vc = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        vc.completionWithItemsHandler = { _, completed, _, _ in
            isExporting = false
            HapticManager.success()
            if completed {
                AchievementManager.shared.recordExport()
                AchievementManager.shared.refresh(gallery: GalleryManager.shared, streak: StreakManager.shared)
            }
        }
        root.present(vc, animated: true)
    }
}
