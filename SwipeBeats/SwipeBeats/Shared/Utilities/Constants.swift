import Foundation

enum Constants {
    // MARK: - Default search
    nonisolated static let defaultSearchTerm = "lofi"
    nonisolated static let defaultSearchLimit = 25

    // MARK: - Quick presets (for future UI picker)
    static let searchPresets: [SearchPreset] = [
        .init(title: "Lo-Fi", term: "lofi"),
        .init(title: "Klassik", term: "classical music"),
        .init(title: "Piano", term: "piano"),
        .init(title: "Jazz", term: "jazz"),
        .init(title: "Indie", term: "indie"),
        .init(title: "K-Pop", term: "k-pop"),
        .init(title: "Hip-Hop", term: "hip hop"),
        .init(title: "EDM", term: "edm"),
        .init(title: "Ambient", term: "ambient"),
        .init(title: "Soundtracks", term: "soundtrack")
    ]
}

struct SearchPreset: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let term: String
}
