import Foundation
import Combine
import SwiftData


@MainActor
final class ExploreViewModel: ObservableObject {

    enum ViewState: Equatable {
        case idle
        case loading
        case empty
        case content
        case error(String)
    }

    enum SortOption: String, CaseIterable, Identifiable {
        case relevance = "Relevanz"
        case trackAZ = "Track A–Z"
        case artistAZ = "Artist A–Z"

        var id: String { rawValue }
    }

    @Published var query: String = ""
    @Published var limit: Int = Constants.defaultSearchLimit
    @Published var onlyWithPreview: Bool = true
    @Published var sortOption: SortOption = .relevance
    @Published private(set) var state: ViewState = .idle
    @Published private(set) var lastSearchedTerm: String = ""
    @Published private(set) var results: [Track] = []
    @Published private(set) var allResults: [Track] = []

    private let service: ITunesSearching
    private var lastSearchMode: SearchPreset.Mode = .keyword

    private let historyKey = "SwipeBeats.Explore.RecentSearches"
    private let historyLimit = 8

    @Published private(set) var recentSearches: [String] = []
    private var recentSearchEntries: [String] = []

    private var searchTask: Task<Void, Never>?
    private var likesStore: LikedTracksStore?
    @Published private(set) var likedIds: Set<Int> = []
    private var cancellables = Set<AnyCancellable>()

    init(service: ITunesSearching? = nil) {
        self.service = service ?? ITunesSearchService()
        recentSearchEntries = loadHistory()
        recentSearches = recentSearchEntries.map { parseEntry($0).term }
    }

    func configureLikesStore(context: ModelContext) {
        if likesStore == nil {
            likesStore = LikedTracksStore(context: context)
            likesStore?.$likedIds
                .receive(on: DispatchQueue.main)
                .sink { [weak self] ids in
                    self?.likedIds = ids
                }
                .store(in: &cancellables)
        }
    }

    func isLiked(trackId: Int) -> Bool {
        likedIds.contains(trackId)
    }

    func like(_ track: Track) {
        likesStore?.like(track)
    }

    func unlike(trackId: Int) {
        likesStore?.unlike(trackId: trackId)
    }

    func loadPreset(_ preset: SearchPreset) async {
        query = preset.term
        lastSearchMode = preset.mode
        await search(term: preset.term, mode: preset.mode, genreId: preset.genreId, allowedPrimaryGenres: preset.allowedPrimaryGenres)
    }

    func searchCurrentQuery(forceKeyword: Bool = true) async {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else {
            results = []
            allResults = []
            lastSearchedTerm = ""
            state = .idle
            return
        }
        if forceKeyword {
            lastSearchMode = .keyword
            await search(term: term, mode: .keyword)
        } else {
            await search(term: term, mode: lastSearchMode)
        }
    }

    func applyFilters(forceStateUpdate: Bool = false) {
        // Don’t override an error state; user should retry search.
        if case .error = state { return }

        // 1) Filter
        let filtered: [Track]
        if onlyWithPreview {
            filtered = allResults.filter { $0.previewURL != nil }
        } else {
            filtered = allResults
        }

        // 2) Sort (local)
        let sorted = applySorting(to: filtered)

        results = sorted

        if case .loading = state, forceStateUpdate == false { return }

        // If we haven’t searched yet, keep idle.
        guard !lastSearchedTerm.isEmpty else {
            state = .idle
            return
        }

        state = sorted.isEmpty ? .empty : .content
    }

    private func applySorting(to items: [Track]) -> [Track] {
        switch sortOption {
        case .relevance:
            // Keep API order
            return items
        case .trackAZ:
            return items.sorted { lhs, rhs in
                lhs.trackName.localizedCaseInsensitiveCompare(rhs.trackName) == .orderedAscending
            }
        case .artistAZ:
            return items.sorted { lhs, rhs in
                lhs.artistName.localizedCaseInsensitiveCompare(rhs.artistName) == .orderedAscending
            }
        }
    }

    func useRecent(_ term: String) async {
        query = term
        if let entry = recentSearchEntries.first(where: { parseEntry($0).term.caseInsensitiveCompare(term) == .orderedSame }) {
            let parsed = parseEntry(entry)
            lastSearchMode = parsed.mode
            await search(term: parsed.term, mode: parsed.mode)
        } else {
            lastSearchMode = .keyword
            await search(term: term, mode: lastSearchMode)
        }
    }

    func clearHistory() {
        recentSearches = []
        recentSearchEntries = []
        UserDefaults.standard.removeObject(forKey: historyKey)
    }

    private func addToHistory(_ term: String) {
        let normalized = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }

        let entry = encodeEntry(term: normalized, mode: lastSearchMode)

        // Move to front, de-duplicate by term (case-insensitive)
        recentSearchEntries.removeAll {
            let parsed = parseEntry($0)
            return parsed.term.caseInsensitiveCompare(normalized) == .orderedSame
        }
        recentSearchEntries.insert(entry, at: 0)

        if recentSearchEntries.count > historyLimit {
            recentSearchEntries = Array(recentSearchEntries.prefix(historyLimit))
        }

        recentSearches = recentSearchEntries.map { parseEntry($0).term }
        saveHistory(recentSearchEntries)
    }

    private func loadHistory() -> [String] {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }

    private func saveHistory(_ items: [String]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: historyKey)
    }

    private func encodeEntry(term: String, mode: SearchPreset.Mode) -> String {
        "\(term)|\(mode.rawValue)"
    }

    private func parseEntry(_ entry: String) -> (term: String, mode: SearchPreset.Mode) {
        guard let separator = entry.lastIndex(of: "|") else {
            return (entry, .keyword)
        }
        let term = String(entry[..<separator])
        let modeRaw = String(entry[entry.index(after: separator)...])
        let mode = SearchPreset.Mode(rawValue: modeRaw) ?? .keyword
        return (term, mode)
    }

    private func search(
        term: String,
        mode: SearchPreset.Mode,
        genreId: Int? = nil,
        allowedPrimaryGenres: [String] = []
    ) async {
        searchTask?.cancel()

        let task = Task { @MainActor in
            if Task.isCancelled { return }

            state = .loading
            lastSearchedTerm = term
            lastSearchMode = mode

            do {
                let items = try await service.search(term: term, limit: limit, mode: mode, genreId: genreId)
                if Task.isCancelled { return }

                let filtered = filterByPrimaryGenreIfNeeded(
                    items,
                    mode: mode,
                    allowedPrimaryGenres: allowedPrimaryGenres
                )

                allResults = filtered
                addToHistory(term)
                applyFilters(forceStateUpdate: true)
            } catch {
                if Task.isCancelled { return }

                if error is DecodingError {
                    state = .error(AppError.decoding.errorDescription ?? "Fehler")
                } else if (error as? URLError) != nil {
                    state = .error(AppError.network.errorDescription ?? "Fehler")
                } else {
                    state = .error(AppError.unknown.errorDescription ?? "Fehler")
                }
            }
        }

        searchTask = task
        await task.value
    }

    private func filterByPrimaryGenreIfNeeded(
        _ items: [Track],
        mode: SearchPreset.Mode,
        allowedPrimaryGenres: [String]
    ) -> [Track] {
        guard mode == .genre, !allowedPrimaryGenres.isEmpty else { return items }

        let allowed = Set(allowedPrimaryGenres.map { $0.lowercased() })
        let filtered = items.filter { track in
            guard let genre = track.primaryGenreName?.lowercased() else { return false }
            return allowed.contains(genre)
        }

        if filtered.isEmpty, !items.isEmpty {
            return items
        }
        return filtered
    }
}

// Smoke test:
// - Preset "Klassik": primaryGenreName should mostly be "Classical"
// - Preset "EDM": should prefer "Dance"/"Electronic"
// - Preset "Solo Piano" (keyword): unchanged results
