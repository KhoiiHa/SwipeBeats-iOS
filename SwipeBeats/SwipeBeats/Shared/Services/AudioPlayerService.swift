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
    var hasActivePlaybackContext: Bool {
        state != .stopped && (nowPlayingTrack != nil || nowPlayingTitle != nil || lastPreviewURL != nil)
    }

    func play(url: URL) {
        if lastPreviewURL == url, state == .paused, player != nil {
            resumeCurrentPlayback()
            syncNowPlaying(for: url)
            return
        }

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

    private func resumeCurrentPlayback() {
        player?.play()
        state = .playing
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
            case .paused:
                if lastPreviewURL == url, player != nil {
                    resumeCurrentPlayback()
                } else {
                    play(url: url)
                }
            case .stopped, .failed:
                play(url: url)
            }
            return
        }

        switch state {
        case .playing:
            pause()
        case .paused:
            if player != nil {
                resumeCurrentPlayback()
            } else if let lastPreviewURL {
                play(url: lastPreviewURL)
            }
        case .stopped, .failed:
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
