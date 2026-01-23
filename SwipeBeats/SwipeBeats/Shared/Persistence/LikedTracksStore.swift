import Foundation
import SwiftData

@MainActor
final class LikedTracksStore {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func isLiked(trackId: Int) -> Bool {
        let descriptor = FetchDescriptor<LikedTrackEntity>(
            predicate: #Predicate { $0.trackId == trackId }
        )
        let count = (try? context.fetchCount(descriptor)) ?? 0
        return count > 0
    }

    func like(_ track: Track) {
        guard !isLiked(trackId: track.id) else { return }

        let entity = LikedTrackEntity(
            trackId: track.id,
            trackName: track.trackName,
            artistName: track.artistName,
            artworkURL: track.artworkURL?.absoluteString,
            previewURL: track.previewURL?.absoluteString,
            collectionViewURL: track.collectionViewURL?.absoluteString
        )

        context.insert(entity)
        try? context.save()
    }

    func unlike(trackId: Int) {
        let descriptor = FetchDescriptor<LikedTrackEntity>(
            predicate: #Predicate { $0.trackId == trackId }
        )
        if let entity = try? context.fetch(descriptor).first {
            context.delete(entity)
            try? context.save()
        }
    }
}
