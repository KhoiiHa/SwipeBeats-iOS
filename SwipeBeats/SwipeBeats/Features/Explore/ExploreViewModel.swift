import Foundation
import Combine

@MainActor
final class ExploreViewModel: ObservableObject {

    enum ViewState: Equatable {
        case idle
        case loading
        case empty
        case content
        case error(String)
    }

    @Published var query: String = ""
    @Published private(set) var state: ViewState = .idle
    @Published private(set) var results: [Track] = []

    private let service: ITunesSearching

    init(service: ITunesSearching? = nil) {
        self.service = service ?? ITunesSearchService()
    }

    func loadPreset(term: String) async {
        query = term
        await search(term: term)
    }

    func searchCurrentQuery() async {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else {
            results = []
            state = .idle
            return
        }
        await search(term: term)
    }

    private func search(term: String) async {
        state = .loading

        do {
            let items = try await service.search(term: term, limit: Constants.defaultSearchLimit)
            results = items
            state = items.isEmpty ? .empty : .content
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
}
