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

    private var player: AVPlayer?

    func play(url: URL) {
        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        player?.play()
        state = .playing
    }

    func pause() {
        player?.pause()
        state = .paused
    }

    func stop() {
        player?.pause()
        player = nil
        state = .stopped
    }

    func toggle(url: URL?) {
        guard let url else { return }
        switch state {
        case .playing:
            pause()
        case .paused, .stopped, .failed:
            play(url: url)
        }
    }
}
