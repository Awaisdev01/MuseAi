import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

enum UpscaleLevel: Int, CaseIterable, Identifiable {
    case x2 = 2
    case x3 = 3
    case x4 = 4

    var id: Int { rawValue }

    var displayName: String { "\(rawValue)x" }

    var description: String {
        switch self {
        case .x2: return "2x — Sharp"
        case .x3: return "3x — Detailed"
        case .x4: return "4x — Maximum"
        }
    }
}

enum ImageUpscaler {

    private static let context = CIContext(options: [.useSoftwareRenderer: false])

    static func upscale(_ image: UIImage, level: UpscaleLevel) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let ciImage = CIImage(cgImage: cgImage)
        let scale = Double(level.rawValue)

        guard let filter = CIFilter(name: "CILanczosScaleTransform") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(scale, forKey: kCIInputScaleKey)
        filter.setValue(1.0, forKey: kCIInputAspectRatioKey)

        guard let outputImage = filter.outputImage else { return nil }

        let sharpen = CIFilter(name: "CISharpenLuminance")!
        sharpen.setValue(outputImage, forKey: kCIInputImageKey)
        sharpen.setValue(0.4, forKey: kCIInputSharpnessKey)

        guard let sharpened = sharpen.outputImage,
              let outputCG = context.createCGImage(sharpened, from: sharpened.extent) else {
            if let fallback = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: fallback, scale: image.scale, orientation: image.imageOrientation)
            }
            return nil
        }

        return UIImage(cgImage: outputCG, scale: image.scale, orientation: image.imageOrientation)
    }

    static func resolution(of image: UIImage) -> String {
        guard let cg = image.cgImage else { return "Unknown" }
        return "\(cg.width) × \(cg.height)"
    }

    static func estimatedResolution(of image: UIImage, at level: UpscaleLevel) -> String {
        guard let cg = image.cgImage else { return "Unknown" }
        let w = cg.width * level.rawValue
        let h = cg.height * level.rawValue
        return "\(w) × \(h)"
    }
}
