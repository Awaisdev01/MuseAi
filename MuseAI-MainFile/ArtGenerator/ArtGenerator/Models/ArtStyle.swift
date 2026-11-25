import SwiftUI

struct ArtStylePreset: Identifiable, Equatable {
    let id: String
    let name: String
    let icon: String
    let promptSuffix: String
    let color: Color

    static let none = ArtStylePreset(
        id: "none", name: "None", icon: "sparkles",
        promptSuffix: "", color: .gray
    )

    static let allStyles: [ArtStylePreset] = [
        ArtStylePreset(
            id: "photorealistic", name: "Photorealistic", icon: "camera.fill",
            promptSuffix: "ultra realistic photograph, 8k, sharp focus, professional photography, natural lighting",
            color: .blue
        ),
        ArtStylePreset(
            id: "digital_art", name: "Digital Art", icon: "paintbrush.fill",
            promptSuffix: "digital painting, artstation, concept art, smooth, sharp focus, illustration",
            color: .purple
        ),
        ArtStylePreset(
            id: "anime", name: "Anime", icon: "star.fill",
            promptSuffix: "anime style, studio ghibli, vibrant colors, detailed, manga illustration",
            color: .pink
        ),
        ArtStylePreset(
            id: "oil_painting", name: "Oil Painting", icon: "paintpalette.fill",
            promptSuffix: "oil painting, canvas texture, rich colors, classical art, masterwork",
            color: .orange
        ),
        ArtStylePreset(
            id: "watercolor", name: "Watercolor", icon: "drop.fill",
            promptSuffix: "watercolor painting, soft edges, delicate washes, artistic, flowing colors",
            color: .cyan
        ),
        ArtStylePreset(
            id: "3d_render", name: "3D Render", icon: "cube.fill",
            promptSuffix: "3D render, octane render, volumetric lighting, highly detailed, cinema 4D",
            color: .green
        ),
        ArtStylePreset(
            id: "pixel_art", name: "Pixel Art", icon: "square.grid.3x3.fill",
            promptSuffix: "pixel art, retro game style, 16-bit, detailed sprites, nostalgic",
            color: .red
        ),
        ArtStylePreset(
            id: "cinematic", name: "Cinematic", icon: "film.fill",
            promptSuffix: "cinematic shot, dramatic lighting, movie scene, anamorphic, color graded",
            color: .indigo
        ),
        ArtStylePreset(
            id: "fantasy", name: "Fantasy", icon: "wand.and.stars",
            promptSuffix: "fantasy art, magical, ethereal glow, enchanted, epic composition, detailed",
            color: .mint
        ),
        ArtStylePreset(
            id: "minimalist", name: "Minimalist", icon: "circle.fill",
            promptSuffix: "minimalist, clean lines, simple composition, modern design, elegant",
            color: .secondary
        ),
        ArtStylePreset(
            id: "comic", name: "Comic Book", icon: "text.bubble.fill",
            promptSuffix: "comic book style, bold outlines, halftone dots, vibrant, graphic novel",
            color: .yellow
        ),
        ArtStylePreset(
            id: "sketch", name: "Sketch", icon: "pencil.tip",
            promptSuffix: "pencil sketch, hand drawn, detailed linework, charcoal, fine art",
            color: Color(.systemGray)
        )
    ]
}
