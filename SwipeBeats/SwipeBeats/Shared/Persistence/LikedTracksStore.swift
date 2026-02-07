import Foundation
import SwiftData
import os

@MainActor
final class LikedTracksStore {

    private let context: ModelContext
    private let logger = Logger(subsystem: "SwipeBeats", category: "LikedTracksStore")
    private var likedIdsCache: Set<Int> = []
    @Published private(set) var likedIds: Set<Int> = []

    init(context: ModelContext) {
        self.context = context
        loadCache()
    }

    func isLiked(trackId: Int) -> Bool {
        likedIdsCache.contains(trackId)
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
            likedIdsCache.insert(track.id)
            likedIds = likedIdsCache
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
                likedIdsCache.remove(trackId)
                likedIds = likedIdsCache
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

    private func loadCache() {
        let descriptor = FetchDescriptor<LikedTrackEntity>()
        let items = (try? context.fetch(descriptor)) ?? []
        likedIdsCache = Set(items.map { $0.trackId })
        likedIds = likedIdsCache
    }
}
