import SwiftUI

struct GenerationTimerView: View {
    let settings: GenerationSettings
    @State private var elapsed: TimeInterval = 0
    @State private var timer: Timer?

    private var estimatedSeconds: Int {
        var base = 15
        if settings.quality == .high { base += 12 }
        else if settings.quality == .medium { base += 5 }
        if settings.size != .square1024 { base += 5 }
        return base
    }

    private var progress: Double {
        min(elapsed / Double(estimatedSeconds), 0.95)
    }

    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            ZStack {
                Circle()
                    .stroke(DS.Colors.surface, lineWidth: 4)
                    .frame(width: 72, height: 72)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        DS.Gradients.accent,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 72, height: 72)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: progress)

                VStack(spacing: 2) {
                    Text("\(Int(elapsed))s")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(DS.Colors.textPrimary)
                    Text("~\(estimatedSeconds)s")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(DS.Colors.textTertiary)
                }
            }
        }
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
    }

    private func startTimer() {
        elapsed = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            elapsed += 0.5
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
