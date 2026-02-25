import Foundation
import SwiftData

@Model
final class PlaylistEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    var trackIds: [Int]

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = .now,
        trackIds: [Int] = []
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.trackIds = trackIds
    }
}
