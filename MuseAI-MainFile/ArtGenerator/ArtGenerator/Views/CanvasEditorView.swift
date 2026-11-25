import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct CanvasEditorView: View {

    let originalImage: UIImage
    let onSave: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var editedImage: UIImage
    @State private var brightness: Double = 0
    @State private var contrast: Double = 1
    @State private var saturation: Double = 1
    @State private var rotation: Double = 0
    @State private var selectedFilter: ImageFilter = .none
    @State private var textOverlay = ""
    @State private var textColor: Color = .white
    @State private var textSize: Double = 32
    @State private var activeTab: EditorTab = .adjust
    @State private var showCropOptions = false
    @State private var isSaving = false

    private static let context = CIContext(options: [.useSoftwareRenderer: false])

    init(originalImage: UIImage, onSave: @escaping (UIImage) -> Void) {
        self.originalImage = originalImage
        self.onSave = onSave
        _editedImage = State(initialValue: originalImage)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    ImagePreview
                    Divider().background(Color.white.opacity(0.1))
                    EditorTabs
                    EditorControls
                }
            }
            .navigationTitle("Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveEdited() }
                        .fontWeight(.semibold)
                        .disabled(isSaving)
                }
            }
        }
    }

    // MARK: - Preview
    private var ImagePreview: some View {
        GeometryReader { geo in
            ZStack {
                Image(uiImage: editedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .rotationEffect(.degrees(rotation))
                    .frame(maxWidth: geo.size.width, maxHeight: geo.size.height)

                if !textOverlay.isEmpty {
                    Text(textOverlay)
                        .font(.system(size: textSize, weight: .bold))
                        .foregroundColor(textColor)
                        .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                        .padding()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(16)
        .accessibilityLabel("Image preview with edits applied")
    }

    // MARK: - Tabs
    private var EditorTabs: some View {
        HStack(spacing: 0) {
            ForEach(EditorTab.allCases, id: \.self) { tab in
                Button {
                    HapticManager.selectionChanged()
                    withAnimation { activeTab = tab }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16))
                        Text(tab.title)
                            .font(.caption2)
                    }
                    .foregroundColor(activeTab == tab ? Color(.label) : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(activeTab == tab ? .isSelected : [])
            }
        }
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - Controls
    @ViewBuilder
    private var EditorControls: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                switch activeTab {
                case .adjust:
                    AdjustControls
                case .filters:
                    FilterControls
                case .crop:
                    CropControls
                case .text:
                    TextControls
                }
            }
            .padding(16)
        }
        .frame(height: 200)
    }

    // MARK: - Adjust
    private var AdjustControls: some View {
        VStack(spacing: 14) {
            SliderRow(label: "Brightness", value: $brightness, range: -0.5...0.5, icon: "sun.max") {
                applyAdjustments()
            }
            SliderRow(label: "Contrast", value: $contrast, range: 0.5...1.5, icon: "circle.righthalf.filled") {
                applyAdjustments()
            }
            SliderRow(label: "Saturation", value: $saturation, range: 0...2, icon: "drop.halffull") {
                applyAdjustments()
            }
            Button("Reset") {
                HapticManager.tap()
                brightness = 0; contrast = 1; saturation = 1
                editedImage = originalImage
            }
            .font(.caption.weight(.medium))
            .foregroundColor(.secondary)
        }
    }

    // MARK: - Filters
    private var FilterControls: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ImageFilter.allCases, id: \.self) { filter in
                    Button {
                        HapticManager.selectionChanged()
                        selectedFilter = filter
                        applyFilter(filter)
                    } label: {
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(filter.previewColor)
                                .frame(width: 56, height: 56)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .strokeBorder(selectedFilter == filter ? DS.Colors.accent : Color.clear, lineWidth: 2)
                                )
                            Text(filter.displayName)
                                .font(.caption2)
                                .foregroundColor(selectedFilter == filter ? Color(.label) : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(filter.displayName) filter")
                }
            }
        }
    }

    // MARK: - Crop
    private var CropControls: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                RotateButton(icon: "rotate.left", label: "Left") {
                    HapticManager.impact()
                    withAnimation { rotation -= 90 }
                }
                RotateButton(icon: "rotate.right", label: "Right") {
                    HapticManager.impact()
                    withAnimation { rotation += 90 }
                }
                RotateButton(icon: "arrow.left.and.right.righttriangle.left.righttriangle.right", label: "Flip H") {
                    HapticManager.impact()
                    flipHorizontal()
                }
                RotateButton(icon: "arrow.up.and.down.righttriangle.up.righttriangle.down", label: "Flip V") {
                    HapticManager.impact()
                    flipVertical()
                }
            }
        }
    }

    // MARK: - Text
    private var TextControls: some View {
        VStack(spacing: 14) {
            TextField("Enter text overlay...", text: $textOverlay)
                .font(.body).foregroundColor(Color(.label))
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.white.opacity(0.06)))
                .tint(DS.Colors.accent)

            SliderRow(label: "Size", value: $textSize, range: 16...72, icon: "textformat.size") {}

            HStack(spacing: 10) {
                ForEach([Color.white, .black, .red, .blue, .yellow, .green, .purple, .orange], id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle().strokeBorder(textColor == color ? Color.white : Color.clear, lineWidth: 2)
                        )
                        .onTapGesture {
                            HapticManager.selectionChanged()
                            textColor = color
                        }
                        .accessibilityLabel("\(color.description) text color")
                }
            }
        }
    }

    // MARK: - Image Processing
    private func applyAdjustments() {
        guard let ciImage = CIImage(image: originalImage) else { return }

        let filter = CIFilter(name: "CIColorControls")!
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(brightness, forKey: kCIInputBrightnessKey)
        filter.setValue(contrast, forKey: kCIInputContrastKey)
        filter.setValue(saturation, forKey: kCIInputSaturationKey)

        guard let output = filter.outputImage,
              let cgImage = Self.context.createCGImage(output, from: output.extent) else { return }
        editedImage = UIImage(cgImage: cgImage, scale: originalImage.scale, orientation: originalImage.imageOrientation)
    }

    private func applyFilter(_ filter: ImageFilter) {
        guard filter != .none else { editedImage = originalImage; return }
        guard let ciImage = CIImage(image: originalImage) else { return }

        guard let ciFilter = CIFilter(name: filter.ciFilterName) else { return }
        ciFilter.setValue(ciImage, forKey: kCIInputImageKey)

        if let intensity = filter.intensity {
            ciFilter.setValue(intensity, forKey: kCIInputIntensityKey)
        }

        guard let output = ciFilter.outputImage,
              let cgImage = Self.context.createCGImage(output, from: output.extent) else { return }
        editedImage = UIImage(cgImage: cgImage, scale: originalImage.scale, orientation: originalImage.imageOrientation)
    }

    private func flipHorizontal() {
        guard let cgImage = editedImage.cgImage else { return }
        editedImage = UIImage(cgImage: cgImage, scale: editedImage.scale, orientation: .upMirrored)
    }

    private func flipVertical() {
        guard let cgImage = editedImage.cgImage else { return }
        editedImage = UIImage(cgImage: cgImage, scale: editedImage.scale, orientation: .downMirrored)
    }

    private func saveEdited() {
        isSaving = true
        HapticManager.impact()

        let renderer = UIGraphicsImageRenderer(size: editedImage.size)
        let final = renderer.image { ctx in
            editedImage.draw(at: .zero)
            if !textOverlay.isEmpty {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: textSize * (editedImage.size.width / UIScreen.main.bounds.width)),
                    .foregroundColor: UIColor(textColor),
                    .shadow: {
                        let s = NSShadow()
                        s.shadowColor = UIColor.black.withAlphaComponent(0.5)
                        s.shadowBlurRadius = 4
                        s.shadowOffset = CGSize(width: 0, height: 2)
                        return s
                    }()
                ]
                let str = NSString(string: textOverlay)
                let size = str.size(withAttributes: attrs)
                let point = CGPoint(
                    x: (editedImage.size.width - size.width) / 2,
                    y: (editedImage.size.height - size.height) / 2
                )
                str.draw(at: point, withAttributes: attrs)
            }
        }

        onSave(final)
        HapticManager.success()
        dismiss()
    }
}

// MARK: - Editor Tab
enum EditorTab: CaseIterable {
    case adjust, filters, crop, text

    var title: String {
        switch self {
        case .adjust: return "Adjust"
        case .filters: return "Filters"
        case .crop: return "Transform"
        case .text: return "Text"
        }
    }

    var icon: String {
        switch self {
        case .adjust: return "slider.horizontal.3"
        case .filters: return "camera.filters"
        case .crop: return "crop.rotate"
        case .text: return "textformat"
        }
    }
}

// MARK: - Image Filter
enum ImageFilter: CaseIterable {
    case none, mono, sepia, chrome, fade, instant, process, tonal, transfer

    var displayName: String {
        switch self {
        case .none: return "Original"
        case .mono: return "Mono"
        case .sepia: return "Sepia"
        case .chrome: return "Chrome"
        case .fade: return "Fade"
        case .instant: return "Instant"
        case .process: return "Process"
        case .tonal: return "Tonal"
        case .transfer: return "Transfer"
        }
    }

    var ciFilterName: String {
        switch self {
        case .none: return ""
        case .mono: return "CIPhotoEffectMono"
        case .sepia: return "CISepiaTone"
        case .chrome: return "CIPhotoEffectChrome"
        case .fade: return "CIPhotoEffectFade"
        case .instant: return "CIPhotoEffectInstant"
        case .process: return "CIPhotoEffectProcess"
        case .tonal: return "CIPhotoEffectTonal"
        case .transfer: return "CIPhotoEffectTransfer"
        }
    }

    var intensity: NSNumber? {
        switch self {
        case .sepia: return 0.8
        default: return nil
        }
    }

    var previewColor: Color {
        switch self {
        case .none: return .gray
        case .mono: return .white.opacity(0.3)
        case .sepia: return .brown.opacity(0.5)
        case .chrome: return .blue.opacity(0.3)
        case .fade: return .gray.opacity(0.4)
        case .instant: return .orange.opacity(0.3)
        case .process: return .teal.opacity(0.3)
        case .tonal: return .gray.opacity(0.5)
        case .transfer: return .yellow.opacity(0.3)
        }
    }
}

// MARK: - Slider Row
private struct SliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let icon: String
    let onChange: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption).foregroundColor(.secondary)
                .frame(width: 20)
            Text(label)
                .font(.caption).foregroundColor(.secondary)
                .frame(width: 70, alignment: .leading)
            Slider(value: $value, in: range)
                .tint(DS.Colors.accent)
                .onChange(of: value) { _ in onChange() }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Rotate Button
private struct RotateButton: View {
    let icon: String; let label: String; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.title3)
                Text(label).font(.caption2)
            }
            .foregroundColor(.white.opacity(0.8))
            .frame(maxWidth: .infinity).frame(height: 56)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(0.08)))
        }.buttonStyle(.plain).accessibilityLabel(label)
    }
}
