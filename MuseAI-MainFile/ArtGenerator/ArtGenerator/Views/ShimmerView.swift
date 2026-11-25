import SwiftUI

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.08),
                            Color.white.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 2)
                    .offset(x: geo.size.width * phase)
                    .onAppear {
                        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                            phase = 1
                        }
                    }
                }
            )
            .clipped()
    }
}

struct SkeletonBox: View {
    var width: CGFloat? = nil
    var height: CGFloat = 16
    var radius: CGFloat = DS.Radius.small

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(DS.Colors.surface)
            .frame(width: width, height: height)
            .modifier(ShimmerModifier())
    }
}

struct SkeletonGalleryCell: View {
    var body: some View {
        RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous)
            .fill(DS.Colors.surface)
            .aspectRatio(1, contentMode: .fit)
            .modifier(ShimmerModifier())
    }
}

struct SkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            SkeletonBox(height: 160, radius: DS.Radius.large)
            SkeletonBox(width: 180, height: 14)
            SkeletonBox(width: 120, height: 12)
        }
        .padding(DS.Spacing.lg)
        .solidCard()
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
