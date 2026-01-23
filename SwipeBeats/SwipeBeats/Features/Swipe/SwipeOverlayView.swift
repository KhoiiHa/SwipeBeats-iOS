import SwiftUI

struct SwipeOverlayView: View {
    let decision: SwipeGestureHandler.Decision
    let opacity: Double

    var body: some View {
        HStack {
            if decision == .like {
                badge(text: "LIKE", systemImage: "hand.thumbsup.fill")
                Spacer()
            } else if decision == .skip {
                Spacer()
                badge(text: "NOPE", systemImage: "hand.thumbsdown.fill")
            } else {
                EmptyView()
            }
        }
        .padding(20)
        .opacity(opacity)
        .animation(.easeInOut(duration: 0.12), value: opacity)
    }

    private func badge(text: String, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.headline)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
