import SwiftUI

struct SwipeCardView: View {
    let track: Track
    @ObservedObject var audio: AudioPlayerService

    var body: some View {
        VStack(spacing: 18) {
            AsyncArtworkImage(url: track.artworkURL)
                .frame(width: 248, height: 248)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: .black.opacity(0.14), radius: 18, x: 0, y: 10)

            VStack(spacing: 8) {
                Text(track.trackName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.center)

                Text(track.artistName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                if let genre = track.primaryGenreName?.trimmingCharacters(in: .whitespacesAndNewlines), !genre.isEmpty {
                    Text(genre)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.secondary.opacity(0.12), in: Capsule())
                }
            }

            previewControls
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.thinMaterial)
                .overlay {
                    LinearGradient(
                        colors: [
                            .white.opacity(0.18),
                            .teal.opacity(0.08),
                            .pink.opacity(0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.24), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 12)
    }

    private var previewControls: some View {
        Button {
            audio.setNowPlaying(track: track)
            audio.toggle(url: track.previewURL)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isCurrentTrackPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(.teal, in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(isCurrentTrackPlaying ? "Vorschau pausieren" : "Vorschau abspielen")
                        .font(.headline)
                    Text("30 Sek. Vorschau")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(.white.opacity(0.18), lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
        .disabled(track.previewURL == nil)
        .opacity(track.previewURL == nil ? 0.5 : 1)
        .accessibilityLabel(isCurrentTrackPlaying ? "Vorschau pausieren" : "Vorschau abspielen")
        .accessibilityHint(track.previewURL == nil ? "Für diesen Track ist keine Vorschau verfügbar" : "Spielt eine 30 Sekunden Vorschau ab")
    }

    private var isCurrentTrackPlaying: Bool {
        guard audio.isPlaying else { return false }
        if let current = audio.nowPlayingTrack {
            return current.id == track.id
        }
        guard let currentURL = audio.lastPreviewURL, let previewURL = track.previewURL else { return false }
        return currentURL == previewURL
    }
}
