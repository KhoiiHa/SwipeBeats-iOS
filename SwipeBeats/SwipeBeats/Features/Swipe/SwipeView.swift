import SwiftUI

struct SwipeView: View {
    @StateObject private var viewModel: SwipeViewModel
    private let handler = SwipeGestureHandler()

    @State private var dragOffset: CGSize = .zero
    @State private var isAnimatingOut = false

    init(viewModel: SwipeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }


    var body: some View {
        ZStack {
            switch viewModel.state {
            case .loading:
                ProgressView("Loading tracks…")

            case .empty:
                VStack(spacing: 12) {
                    Text("Keine Tracks verfügbar")
                        .font(.headline)

                    Button("Neu laden") {
                        Task { await viewModel.loadInitial() }
                    }
                }

            case .error(let message):
                VStack(spacing: 12) {
                    Text("Fehler")
                        .font(.headline)

                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button("Erneut versuchen") {
                        Task { await viewModel.loadInitial() }
                    }
                }

            case .content:
                if let track = viewModel.currentTrack {
                    let decision = handler.decision(for: dragOffset)
                    let overlayOpacity = handler.overlayOpacity(for: dragOffset)

                    VStack(spacing: 16) {
                        ZStack(alignment: .top) {
                            SwipeCardView(track: track, audio: viewModel.audio)
                                .padding(.horizontal)
                                .offset(x: dragOffset.width, y: dragOffset.height * 0.15)
                                .rotationEffect(handler.rotation(for: dragOffset))
                                .gesture(dragGesture)
                                .animation(.spring(response: 0.3, dampingFraction: 0.85), value: dragOffset)
                                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isAnimatingOut)

                            SwipeOverlayView(decision: decision, opacity: overlayOpacity)
                                .padding(.horizontal)
                        }

                        HStack(spacing: 16) {
                            Button {
                                Task { await animateOutAndAdvance(.skip) }
                            } label: {
                                Label("Skip", systemImage: "xmark")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)

                            Button {
                                Task { await animateOutAndAdvance(.like) }
                            } label: {
                                Label("Like", systemImage: "heart.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.horizontal)
                    }
                } else {
                    Text("Kein Track")
                }
            }
        }
        .task {
            await viewModel.loadInitial()
        }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard !isAnimatingOut else { return }
                dragOffset = value.translation
            }
            .onEnded { value in
                guard !isAnimatingOut else { return }
                let decision = handler.decision(for: value.translation)

                Task {
                    switch decision {
                    case .like:
                        await animateOutAndAdvance(.like)
                    case .skip:
                        await animateOutAndAdvance(.skip)
                    case .none:
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            dragOffset = .zero
                        }
                    }
                }
            }
    }

    @MainActor
    private func animateOutAndAdvance(_ decision: SwipeGestureHandler.Decision) async {
        guard !isAnimatingOut else { return }
        isAnimatingOut = true

        // Fly out direction
        let targetX: CGFloat = (decision == .like) ? 500 : -500

        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            dragOffset = CGSize(width: targetX, height: dragOffset.height)
        }

        // Small delay for the animation to complete
        try? await Task.sleep(nanoseconds: 180_000_000)

        switch decision {
        case .like:
            viewModel.like()
        case .skip:
            viewModel.skip()
        case .none:
            break
        }

        dragOffset = .zero
        isAnimatingOut = false
    }
}
