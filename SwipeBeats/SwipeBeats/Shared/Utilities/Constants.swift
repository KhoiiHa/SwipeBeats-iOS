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
        .init(title: "Klassik", term: "classical", mode: .genre),
        .init(title: "Jazz", term: "jazz", mode: .genre),
        .init(title: "K-Pop", term: "k-pop", mode: .genre),
        .init(title: "Hip-Hop", term: "hip hop", mode: .genre),
        .init(title: "EDM", term: "edm", mode: .genre),
        .init(title: "Ambient", term: "ambient", mode: .genre)
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

    init(title: String, term: String, mode: Mode, genreId: Int? = nil) {
        self.title = title
        self.term = term
        self.mode = mode
        self.genreId = genreId
        self.id = "\(mode.rawValue)|\(term.lowercased())"
    }
}
