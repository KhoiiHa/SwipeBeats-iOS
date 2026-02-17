import Foundation
import Combine
import AVFoundation

@MainActor
final class AudioPlayerService: ObservableObject {

    enum State: Equatable {
        case stopped
        case playing
        case paused
        case failed
    }

    @Published private(set) var state: State = .stopped
    @Published var nowPlayingTrack: Track?
    @Published private(set) var nowPlayingTitle: String?
    @Published private(set) var nowPlayingArtist: String?

    private var player: AVPlayer?
    private(set) var lastPreviewURL: URL?
    private var pendingNowPlayingTrack: Track?

    var isPlaying: Bool { state == .playing }

    func play(url: URL) {
        if let current = lastPreviewURL, current != url {
            stopPlayerOnly()
        }
        lastPreviewURL = url
        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        player?.play()
        syncNowPlaying(for: url)
        state = .playing
    }

    func pause() {
        player?.pause()
        state = .paused
    }

    func stop() {
        stopPlayerOnly()
        nowPlayingTrack = nil
        nowPlayingTitle = nil
        nowPlayingArtist = nil
        pendingNowPlayingTrack = nil
    }

    private func stopPlayerOnly() {
        if let player {
            player.pause()
            player.seek(to: .zero)
        }
        player = nil
        state = .stopped
    }

    func setNowPlaying(title: String, artist: String) {
        nowPlayingTitle = title
        nowPlayingArtist = artist
    }

    func setNowPlaying(track: Track) {
        pendingNowPlayingTrack = track
    }

    func toggle(url: URL?) {
        if let url {
            switch state {
            case .playing:
                if lastPreviewURL == url {
                    pause()
                } else {
                    play(url: url)
                }
            case .paused, .stopped, .failed:
                play(url: url)
            }
            return
        }

        switch state {
        case .playing:
            pause()
        case .paused, .stopped, .failed:
            if let lastPreviewURL {
                play(url: lastPreviewURL)
            }
        }
    }

    private func syncNowPlaying(for url: URL) {
        if let pending = pendingNowPlayingTrack, pending.previewURL == url {
            nowPlayingTrack = pending
            nowPlayingTitle = pending.trackName
            nowPlayingArtist = pending.artistName
            pendingNowPlayingTrack = nil
            return
        }

        if let current = nowPlayingTrack, current.previewURL == url {
            return
        }
    }
}
