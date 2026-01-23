import SwiftUI

struct SwipeCardView: View {
    let track: Track
    @ObservedObject var audio: AudioPlayerService

    var body: some View {
        VStack(spacing: 16) {
            AsyncArtworkImage(url: track.artworkURL)
                .frame(width: 220, height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            VStack(spacing: 6) {
                Text(track.trackName)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                Text(track.artistName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            previewControls
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var previewControls: some View {
        Button {
            audio.toggle(url: track.previewURL)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: audio.state == .playing ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 28, weight: .semibold))

                VStack(alignment: .leading, spacing: 2) {
                    Text(audio.state == .playing ? "Preview pausieren" : "Preview abspielen")
                        .font(.headline)
                    Text("30s Vorschau")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(track.previewURL == nil)
        .opacity(track.previewURL == nil ? 0.5 : 1)
        .accessibilityLabel("Audio Preview")
    }
}
