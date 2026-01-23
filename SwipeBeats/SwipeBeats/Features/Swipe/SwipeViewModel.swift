import Foundation
import Combine

@MainActor
final class SwipeViewModel: ObservableObject {

    enum ViewState: Equatable {
        case loading
        case empty
        case content
        case error(String)
    }

    @Published private(set) var state: ViewState = .loading
    @Published private(set) var tracks: [Track] = []
    @Published private(set) var currentIndex: Int = 0

    private let service: ITunesSearching
    private let likesStore: LikedTracksStore?

    let audio: AudioPlayerService

    // IMPORTANT: avoid `= ITunesSearchService()` default argument
    // Block 3: inject likesStore + audio; likesStore is optional until wiring is done in the root view.
    init(
        service: ITunesSearching? = nil,
        likesStore: LikedTracksStore? = nil,
        audio: AudioPlayerService? = nil
    ) {
        self.service = service ?? ITunesSearchService()
        self.likesStore = likesStore
        self.audio = audio ?? AudioPlayerService()
    }

    func loadInitial() async {
        state = .loading
        currentIndex = 0

        do {
            let result = try await service.search(
                term: Constants.defaultSearchTerm,
                limit: Constants.defaultSearchLimit
            )
            tracks = result

            if tracks.isEmpty {
                state = .empty
            } else {
                state = .content
            }
            playCurrentPreviewIfAvailable()
        } catch {
            if error is DecodingError {
                state = .error(AppError.decoding.errorDescription ?? "Fehler")
            } else if (error as? URLError) != nil {
                state = .error(AppError.network.errorDescription ?? "Fehler")
            } else {
                state = .error(AppError.unknown.errorDescription ?? "Fehler")
            }
        }
    }

    var currentTrack: Track? {
        guard tracks.indices.contains(currentIndex) else { return nil }
        return tracks[currentIndex]
    }

    func skip() {
        goToNext()
        playCurrentPreviewIfAvailable()
    }

    func like() {
        if let track = currentTrack {
            likesStore?.like(track)
        }
        goToNext()
        playCurrentPreviewIfAvailable()
    }

    private func goToNext() {
        let nextIndex = currentIndex + 1
        if tracks.indices.contains(nextIndex) {
            currentIndex = nextIndex
            state = .content
        } else {
            state = .empty
        }
    }

    private func playCurrentPreviewIfAvailable() {
        audio.stop()
        if let url = currentTrack?.previewURL {
            audio.play(url: url)
        }
    }
}
