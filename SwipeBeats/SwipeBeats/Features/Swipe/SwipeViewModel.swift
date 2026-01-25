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
    @Published private(set) var currentSearchTerm: String = Constants.defaultSearchTerm

    private let service: ITunesSearching
    private let likesStore: LikedTracksStore?

    let audio: AudioPlayerService

    // IMPORTANT: avoid `= ITunesSearchService()` and `= AudioPlayerService()` default arguments (actor-isolation issue)
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
        await load(term: Constants.defaultSearchTerm)
    }

    func load(term: String, limit: Int = Constants.defaultSearchLimit) async {
        state = .loading
        currentIndex = 0
        currentSearchTerm = term

        do {
            let result = try await service.search(term: term, limit: limit)
            tracks = result
            state = tracks.isEmpty ? .empty : .content
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
