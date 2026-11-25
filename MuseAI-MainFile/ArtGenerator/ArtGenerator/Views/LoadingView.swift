import SwiftUI

struct LoadingView: View {

    @Binding var isLoading: Bool
    var message: String = "Loading..."

    var body: some View {
        if isLoading {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)

                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.primary)
                    Text(message)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                }
                .padding(28)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
                .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
            .animation(.easeOut(duration: 0.25), value: isLoading)
        }
    }
}
