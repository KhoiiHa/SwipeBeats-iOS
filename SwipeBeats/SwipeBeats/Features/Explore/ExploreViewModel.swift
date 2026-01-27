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
    @Published var limit: Int = Constants.defaultSearchLimit
    @Published var onlyWithPreview: Bool = true
    @Published private(set) var state: ViewState = .idle
    @Published private(set) var lastSearchedTerm: String = ""
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

    func setLimit(_ newLimit: Int) async {
        limit = newLimit
        await searchCurrentQuery()
    }

    func setOnlyWithPreview(_ enabled: Bool) async {
        onlyWithPreview = enabled
        await searchCurrentQuery()
    }

    private func search(term: String) async {
        state = .loading
        lastSearchedTerm = term

        do {
            let items = try await service.search(term: term, limit: limit)

            let filtered: [Track]
            if onlyWithPreview {
                filtered = items.filter { $0.previewURL != nil }
            } else {
                filtered = items
            }

            results = filtered
            state = filtered.isEmpty ? .empty : .content
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
