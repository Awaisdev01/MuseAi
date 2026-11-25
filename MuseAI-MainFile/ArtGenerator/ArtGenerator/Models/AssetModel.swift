import Foundation

struct AssetModel: Identifiable {
    let id = UUID()
    let imageName: String
    let imageText: String
    let isHorizontal: Bool
    let category: String
}
