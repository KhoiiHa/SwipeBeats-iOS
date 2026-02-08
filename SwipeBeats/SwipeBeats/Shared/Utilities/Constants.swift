import Foundation

enum Constants {
    // MARK: - Default search
    // Must match an existing `searchPresets.id` value (used as Picker tags).
    nonisolated static let defaultSearchPresetId = "keyword|lofi beats"
    // Legacy alias for older call sites.
    nonisolated static let defaultSearchTerm = "lofi beats"
    nonisolated static let defaultSearchLimit = 25

    // MARK: - Quick presets (for future UI picker)
    static let searchPresets: [SearchPreset] = [
        // NOTE: iTunes Search is fuzzy by default.
        // - `.genre` presets will be narrowed via `attribute=genreIndex`.
        // - `.keyword` presets are "vibe" searches (more specific terms reduce false positives).

        // Vibes / Keywords (more specific than single words like "piano")
        .init(title: "Lo-Fi Beats", term: "lofi beats", mode: .keyword),
        .init(title: "Solo Piano", term: "solo piano", mode: .keyword),
        .init(title: "Indie Rock", term: "indie rock", mode: .keyword),
        .init(title: "Film Score", term: "film score", mode: .keyword),

        // Genres
        .init(title: "Klassik", term: "classical instrumental", mode: .genre, allowedPrimaryGenres: ["Classical"]),
        .init(title: "Jazz", term: "jazz", mode: .genre, allowedPrimaryGenres: ["Jazz"]),
        .init(title: "K-Pop", term: "k-pop", mode: .genre, allowedPrimaryGenres: ["K-Pop"]),
        .init(title: "Hip-Hop", term: "hip hop beats", mode: .genre, allowedPrimaryGenres: ["Hip-Hop/Rap"]),
        .init(title: "EDM", term: "electronic dance", mode: .genre, allowedPrimaryGenres: ["Dance", "Electronic"]),
        .init(title: "Ambient", term: "ambient", mode: .genre, allowedPrimaryGenres: ["Ambient", "Electronic"])
    ]
}

struct SearchPreset: Identifiable, Equatable {

    enum Mode: String, CaseIterable {
        case genre
        case keyword
        case artist
        case song
    }

    let id: String
    let title: String
    let term: String
    let mode: Mode
    let genreId: Int?
    let allowedPrimaryGenres: [String]

    init(title: String, term: String, mode: Mode, genreId: Int? = nil, allowedPrimaryGenres: [String] = []) {
        self.title = title
        self.term = term
        self.mode = mode
        self.genreId = genreId
        self.allowedPrimaryGenres = allowedPrimaryGenres
        self.id = "\(mode.rawValue)|\(term.lowercased())"
    }
}
