import Foundation
import SwiftData
import os

@MainActor
final class PlaylistStore {
    private let context: ModelContext
    private let logger = Logger(subsystem: "SwipeBeats", category: "PlaylistStore")

    init(context: ModelContext) {
        self.context = context
    }

    func fetchPlaylists() -> [PlaylistEntity] {
        let descriptor = FetchDescriptor<PlaylistEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            return try context.fetch(descriptor)
        } catch {
            logger.error("Failed to fetch playlists. \(error.localizedDescription)")
            return []
        }
    }

    @discardableResult
    func createPlaylist(name: String) -> PlaylistEntity {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let playlist = PlaylistEntity(name: trimmed.isEmpty ? "Neue Playlist" : trimmed)
        context.insert(playlist)

        do {
            try context.save()
        } catch {
            logger.error("Failed to create playlist '\(playlist.name)'. \(error.localizedDescription)")
            context.delete(playlist)
        }

        return playlist
    }

    func renamePlaylist(id: UUID, newName: String) {
        guard let playlist = findPlaylist(id: id) else { return }
        let oldName = playlist.name
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        playlist.name = trimmed.isEmpty ? oldName : trimmed

        do {
            try context.save()
        } catch {
            logger.error("Failed to rename playlist '\(oldName)'. \(error.localizedDescription)")
            playlist.name = oldName
        }
    }

    func deletePlaylist(id: UUID) {
        guard let playlist = findPlaylist(id: id) else { return }
        context.delete(playlist)

        do {
            try context.save()
        } catch {
            logger.error("Failed to delete playlist (id: \(id.uuidString)). \(error.localizedDescription)")
            context.insert(playlist)
        }
    }

    func addTrack(to playlistId: UUID, track: Track) {
        guard let playlist = findPlaylist(id: playlistId) else { return }
        guard !playlist.tracks.contains(where: { $0.trackId == track.id }) else { return }

        let snapshot = PlaylistTrackSnapshot(
            trackId: track.id,
            title: track.trackName,
            artist: track.artistName,
            artworkUrl: track.artworkURL?.absoluteString,
            previewURL: track.previewURL?.absoluteString
        )
        playlist.tracks.append(snapshot)

        do {
            try context.save()
        } catch {
            logger.error("Failed to add track \(track.id) to playlist \(playlistId.uuidString). \(error.localizedDescription)")
            playlist.tracks.removeAll { $0.trackId == track.id }
        }
    }

    func removeTrack(from playlistId: UUID, trackId: Int) {
        guard let playlist = findPlaylist(id: playlistId) else { return }
        guard let removedSnapshot = playlist.tracks.first(where: { $0.trackId == trackId }) else { return }

        playlist.tracks.removeAll { $0.trackId == trackId }

        do {
            try context.save()
        } catch {
            logger.error("Failed to remove track \(trackId) from playlist \(playlistId.uuidString). \(error.localizedDescription)")
            playlist.tracks.append(removedSnapshot)
        }
    }

    private func findPlaylist(id: UUID) -> PlaylistEntity? {
        let descriptor = FetchDescriptor<PlaylistEntity>(
            predicate: #Predicate { $0.id == id }
        )

        do {
            return try context.fetch(descriptor).first
        } catch {
            logger.error("Failed to fetch playlist (id: \(id.uuidString)). \(error.localizedDescription)")
            return nil
        }
    }
}
