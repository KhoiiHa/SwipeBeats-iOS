import Foundation
import SwiftData
import os

@MainActor
final class LikedTracksStore {

    private let context: ModelContext
    private let logger = Logger(subsystem: "SwipeBeats", category: "LikedTracksStore")

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
        do {
            try context.save()
        } catch {
            logger.error("Failed to save liked track (id: \(track.id)). \(error.localizedDescription)")
            context.delete(entity)
        }
    }

    func unlike(trackId: Int) {
        let descriptor = FetchDescriptor<LikedTrackEntity>(
            predicate: #Predicate { $0.trackId == trackId }
        )
        if let entity = try? context.fetch(descriptor).first {
            let snapshot = (
                uuid: entity.uuid,
                trackId: entity.trackId,
                trackName: entity.trackName,
                artistName: entity.artistName,
                artworkURL: entity.artworkURL,
                previewURL: entity.previewURL,
                collectionViewURL: entity.collectionViewURL,
                createdAt: entity.createdAt
            )
            context.delete(entity)
            do {
                try context.save()
            } catch {
                logger.error("Failed to remove liked track (id: \(trackId)). \(error.localizedDescription)")
                let rollback = LikedTrackEntity(
                    uuid: snapshot.uuid,
                    trackId: snapshot.trackId,
                    trackName: snapshot.trackName,
                    artistName: snapshot.artistName,
                    artworkURL: snapshot.artworkURL,
                    previewURL: snapshot.previewURL,
                    collectionViewURL: snapshot.collectionViewURL,
                    createdAt: snapshot.createdAt
                )
                context.insert(rollback)
            }
        }
    }
}
