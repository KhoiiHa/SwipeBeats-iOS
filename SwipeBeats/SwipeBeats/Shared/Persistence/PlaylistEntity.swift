import Foundation
import SwiftData

struct PlaylistTrackSnapshot: Codable, Hashable, Identifiable {
    var trackId: Int
    var title: String
    var artist: String
    var artworkUrl: String?

    var id: Int { trackId }
}

@Model
final class PlaylistEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    var tracks: [PlaylistTrackSnapshot] = []

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = .now,
        tracks: [PlaylistTrackSnapshot] = []
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.tracks = tracks
    }
}
