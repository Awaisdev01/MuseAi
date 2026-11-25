import SwiftUI

struct ConfettiPiece: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let color: Color
    let size: CGFloat
    let rotation: Double
    let speed: Double
}

struct ConfettiView: View {
    @Binding var isActive: Bool
    @State private var pieces: [ConfettiPiece] = []
    @State private var opacity: Double = 1

    private let colors: [Color] = [
        DS.Colors.accent, DS.Colors.accentLight,
        DS.Colors.success, DS.Colors.warning,
        Color(hex: "EC4899"), Color(hex: "06B6D4")
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(piece.color)
                        .frame(width: piece.size, height: piece.size * 0.6)
                        .rotationEffect(.degrees(piece.rotation))
                        .position(x: piece.x, y: piece.y)
                }
            }
            .opacity(opacity)
            .onChange(of: isActive) { _ in
                if isActive {
                    launchConfetti(in: geo.size)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func launchConfetti(in size: CGSize) {
        opacity = 1
        pieces = (0..<40).map { _ in
            ConfettiPiece(
                x: CGFloat.random(in: 0...size.width),
                y: -20,
                color: colors.randomElement()!,
                size: CGFloat.random(in: 6...12),
                rotation: Double.random(in: 0...360),
                speed: Double.random(in: 0.8...1.5)
            )
        }

        withAnimation(.easeOut(duration: 2.0)) {
            for i in pieces.indices {
                pieces[i].y = size.height + 50
                pieces[i].x += CGFloat.random(in: -80...80)
            }
        }

        withAnimation(.easeIn(duration: 0.5).delay(1.5)) {
            opacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            pieces = []
            isActive = false
        }
    }
}
