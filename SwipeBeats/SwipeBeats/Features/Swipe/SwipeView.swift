import SwiftUI

struct SwipeView: View {
    @StateObject private var viewModel: SwipeViewModel
    let onOpenArtistInExplore: (String) -> Void
    private let handler = SwipeGestureHandler()

    @State private var dragOffset: CGSize = .zero
    @State private var isAnimatingOut = false
    @State private var selectedTerm: String = Constants.defaultSearchPresetId
    @State private var detailTrack: Track?

    init(viewModel: SwipeViewModel, onOpenArtistInExplore: @escaping (String) -> Void) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onOpenArtistInExplore = onOpenArtistInExplore
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .loading:
                VStack(spacing: 16) {
                    searchHeader
                    Spacer()

                    ProgressView("Tracks werden geladen…")

                    Spacer()
                }

            case .empty:
                VStack(spacing: 16) {
                    searchHeader
                    Spacer()

                    ContentUnavailableView(
                        "Keine Tracks verfügbar",
                        systemImage: "music.note",
                        description: Text("Für diese Auswahl wurden keine spielbaren Vorschauen gefunden.")
                    )

                    Button {
                        reloadSelectedTerm()
                    } label: {
                        Label("Neu laden", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.teal)

                    Spacer()
                }

            case .error(let message):
                VStack(spacing: 16) {
                    searchHeader
                    Spacer()

                    ContentUnavailableView(
                        "Fehler",
                        systemImage: "exclamationmark.triangle",
                        description: Text(message.isEmpty ? "Bitte erneut versuchen." : message)
                    )

                    Button {
                        reloadSelectedTerm()
                    } label: {
                        Label("Erneut versuchen", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.teal)

                    Spacer()
                }

            case .content:
                if let track = viewModel.currentTrack {
                    let decision = handler.decision(for: dragOffset)
                    let overlayOpacity = handler.overlayOpacity(for: dragOffset)

                    VStack(spacing: 16) {
                        searchHeader
                        ZStack(alignment: .topTrailing) {
                            SwipeCardView(track: track, audio: viewModel.audio)
                                .padding(.horizontal)
                                .offset(x: dragOffset.width, y: dragOffset.height * 0.15)
                                .rotationEffect(handler.rotation(for: dragOffset))
                                .gesture(dragGesture)
                                .animation(.spring(response: 0.3, dampingFraction: 0.85), value: dragOffset)
                                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isAnimatingOut)

                            Button {
                                detailTrack = track
                            } label: {
                                Image(systemName: "info.circle.fill")
                                    .font(.title2)
                                    .symbolRenderingMode(.hierarchical)
                            }
                            .accessibilityLabel("Track-Details öffnen")
                            .accessibilityHint("Zeigt weitere Informationen zum aktuellen Track")
                            .padding(.trailing, 26)
                            .padding(.top, 18)

                            SwipeOverlayView(decision: decision, opacity: overlayOpacity)
                                .padding(.horizontal)
                        }

                        HStack(spacing: 16) {
                            Button {
                                Task { await animateOutAndAdvance(.skip) }
                            } label: {
                                Label("Überspringen", systemImage: "xmark")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.secondary)
                            .accessibilityLabel("Track überspringen")

                            Button {
                                Task { await animateOutAndAdvance(.like) }
                            } label: {
                                Label("Favorit", systemImage: "heart")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.pink)
                            .accessibilityLabel("Zu Favoriten hinzufügen")
                        }
                        .padding(.horizontal)
                    }
                } else {
                    ContentUnavailableView(
                        "Kein Track",
                        systemImage: "music.note",
                        description: Text("Bitte lade die Auswahl erneut.")
                    )
                }
            }
        }
        .task {
            await viewModel.loadInitialIfNeeded(term: selectedSearchTerm())
        }
        .onChange(of: selectedTerm) { _, newValue in
            // Reset swipe UI state when switching presets
            dragOffset = .zero
            isAnimatingOut = false

            Task { await viewModel.load(term: searchTerm(for: newValue)) }
        }
        .sheet(item: $detailTrack) { track in
            NavigationStack {
                TrackDetailView(
                    track: track,
                    audio: viewModel.audio,
                    onOpenArtist: { artistName in
                        detailTrack = nil
                        onOpenArtistInExplore(artistName)
                    }
                )
            }
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

    private var searchHeader: some View {
        HStack(spacing: 12) {
            Picker("Genre", selection: $selectedTerm) {
                ForEach(Constants.searchPresets) { preset in
                    Text(preset.title).tag(preset.id)
                }
            }
            .pickerStyle(.menu)

            Button {
                reloadSelectedTerm()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .tint(.teal)
            .disabled(viewModel.state == .loading)
        }
        .padding(.horizontal)
    }

    private func selectedSearchTerm() -> String {
        searchTerm(for: selectedTerm)
    }

    private func searchTerm(for value: String) -> String {
        if let preset = Constants.searchPresets.first(where: { $0.id == value }) {
            return preset.term
        }
        return value
    }

    private func reloadSelectedTerm() {
        Task { await viewModel.load(term: selectedSearchTerm()) }
    }
}
