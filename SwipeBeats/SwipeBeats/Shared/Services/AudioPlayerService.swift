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
    @Published private(set) var hasNextTrack = false

    private var player: AVPlayer?
    private(set) var lastPreviewURL: URL?
    private var pendingNowPlayingTrack: Track?
    private var queue: [Track] = []
    private var currentQueueIndex: Int?
    private var playbackEndObserver: NSObjectProtocol?

    var isPlaying: Bool { state == .playing }
    var hasActivePlaybackContext: Bool {
        state != .stopped && (nowPlayingTrack != nil || nowPlayingTitle != nil || lastPreviewURL != nil)
    }

    func play(url: URL) {
        clearQueue()
        play(url: url, resetQueue: false)
    }

    private func play(url: URL, resetQueue: Bool) {
        if resetQueue {
            clearQueue()
        }

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
        observePlaybackEnd(for: item)
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
        clearQueue()
        stopPlayerOnly()
        nowPlayingTrack = nil
        nowPlayingTitle = nil
        nowPlayingArtist = nil
        pendingNowPlayingTrack = nil
    }

    private func stopPlayerOnly() {
        removePlaybackEndObserver()
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

    func playQueue(_ tracks: [Track], startAt index: Int = 0) {
        let playableTracks = tracks.filter { $0.previewURL != nil }
        guard playableTracks.indices.contains(index) else { return }

        queue = playableTracks
        playQueuedTrack(at: index)
    }

    func playNext() {
        guard hasNextTrack, let currentQueueIndex else { return }
        playQueuedTrack(at: currentQueueIndex + 1)
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

    private func playQueuedTrack(at index: Int) {
        guard queue.indices.contains(index),
              let previewURL = queue[index].previewURL else {
            stop()
            return
        }

        currentQueueIndex = index
        setNowPlaying(track: queue[index])
        play(url: previewURL, resetQueue: false)
        updateQueueState()
    }

    private func handlePlaybackEnded() {
        guard let currentQueueIndex else {
            stop()
            return
        }

        let nextIndex = currentQueueIndex + 1
        guard queue.indices.contains(nextIndex) else {
            stop()
            return
        }

        playQueuedTrack(at: nextIndex)
    }

    private func observePlaybackEnd(for item: AVPlayerItem) {
        removePlaybackEndObserver()
        playbackEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handlePlaybackEnded()
            }
        }
    }

    private func removePlaybackEndObserver() {
        if let playbackEndObserver {
            NotificationCenter.default.removeObserver(playbackEndObserver)
            self.playbackEndObserver = nil
        }
    }

    private func clearQueue() {
        queue = []
        currentQueueIndex = nil
        updateQueueState()
    }

    private func updateQueueState() {
        guard let currentQueueIndex else {
            hasNextTrack = false
            return
        }
        hasNextTrack = queue.indices.contains(currentQueueIndex + 1)
    }
}
