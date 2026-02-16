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
    private var hasLoadedInitially = false

    let audio: AudioPlayerService

    // IMPORTANT: avoid `= ITunesSearchService()` and `= AudioPlayerService()` default arguments (actor-isolation issue)
    init(
        service: ITunesSearching? = nil,
        likesStore: LikedTracksStore? = nil,
        audio: AudioPlayerService
    ) {
        self.service = service ?? ITunesSearchService()
        self.likesStore = likesStore
        self.audio = audio
    }

    func loadInitial() async {
        await load(term: Constants.defaultSearchTerm)
    }

    func loadInitialIfNeeded(term: String) async {
        guard hasLoadedInitially == false else { return }
        await load(term: term)
    }

    func load(term: String, limit: Int = Constants.defaultSearchLimit) async {
        state = .loading
        currentIndex = 0
        currentSearchTerm = term

        do {
            let result = try await service.search(term: term, limit: limit)
            tracks = result
            state = tracks.isEmpty ? .empty : .content
            hasLoadedInitially = true
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
        audio.stop()
    }

    func like() {
        if let track = currentTrack {
            likesStore?.like(track)
        }
        goToNext()
        audio.stop()
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

}
