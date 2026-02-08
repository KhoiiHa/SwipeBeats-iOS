import Foundation

// MARK: - Domain Model
struct Track: Identifiable, Equatable {
    let id: Int
    let artistName: String
    let trackName: String
    let artworkURL: URL?
    let previewURL: URL?
    let collectionViewURL: URL?
    let primaryGenreName: String?

    var displayTitle: String { trackName }
    var displaySubtitle: String { artistName }
}

// MARK: - iTunes API DTOs
struct ITunesSearchResponse: Decodable {
    let resultCount: Int
    let results: [ITunesTrackDTO]
}

struct ITunesTrackDTO: Decodable {
    let trackId: Int?
    let artistName: String?
    let trackName: String?
    let artworkUrl100: String?
    let previewUrl: String?
    let collectionViewUrl: String?
    let primaryGenreName: String?

    func toDomain() -> Track? {
        guard
            let trackId,
            let artistName,
            let trackName
        else { return nil }

        return Track(
            id: trackId,
            artistName: artistName,
            trackName: trackName,
            artworkURL: artworkUrl100.flatMap(URL.init(string:)),
            previewURL: previewUrl.flatMap(URL.init(string:)),
            collectionViewURL: collectionViewUrl.flatMap(URL.init(string:)),
            primaryGenreName: primaryGenreName
        )
    }
}
