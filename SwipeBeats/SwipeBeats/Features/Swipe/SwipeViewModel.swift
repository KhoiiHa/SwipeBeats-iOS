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

    // IMPORTANT: avoid `= ITunesSearchService()` default argument
    init(service: ITunesSearching? = nil) {
        self.service = service ?? ITunesSearchService()
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
    }

    func like() {
        // Persist kommt in Block 3
        goToNext()
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
