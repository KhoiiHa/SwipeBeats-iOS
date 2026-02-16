import SwiftUI
import SwiftData

struct TrackDetailView: View {
    let track: Track
    @ObservedObject var audio: AudioPlayerService

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL

    @State private var isLiked = false
    @State private var likesStore: LikedTracksStore?
    let onExploreArtist: ((String) -> Void)?

    init(
        track: Track,
        audio: AudioPlayerService,
        onExploreArtist: ((String) -> Void)? = nil
    ) {
        self.track = track
        self.audio = audio
        self.onExploreArtist = onExploreArtist
    }

    private var isCurrentTrackPlaying: Bool {
        if audio.state != .playing { return false }
        if let now = audio.nowPlayingTrack, now.id == track.id { return true }
        if let preview = track.previewURL, let last = audio.lastPreviewURL { return preview == last }
        return false
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                AsyncArtworkImage(url: track.artworkURL)
                    .frame(width: 260, height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(radius: 12)
                    .padding(.top, 8)

                VStack(spacing: 8) {
                    Text(track.trackName)
                        .font(.title3)
                        .fontWeight(.semibold)
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
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.secondary.opacity(0.12), in: Capsule())
                    }
                }
                .padding(.horizontal)

                HStack(spacing: 10) {
                    Button {
                        audio.setNowPlaying(track: track)
                        audio.toggle(url: track.previewURL)
                    } label: {
                        Label(
                            isCurrentTrackPlaying ? "Pause" : "Play",
                            systemImage: isCurrentTrackPlaying ? "pause.fill" : "play.fill"
                        )
                        .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(track.previewURL == nil)
                    .accessibilityLabel(isCurrentTrackPlaying ? "Pause Preview" : "Play Preview")

                    Button {
                        audio.stop()
                    } label: {
                        Label("Stop", systemImage: "stop.fill")
                            .frame(minWidth: 88, minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!isCurrentTrackPlaying)
                    .accessibilityLabel("Stop Preview")

                    Button {
                        toggleLike()
                    } label: {
                        Label(isLiked ? "Liked" : "Like", systemImage: isLiked ? "heart.fill" : "heart")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)

                if let url = track.collectionViewURL {
                    Button {
                        openURL(url)
                    } label: {
                        Label("In Apple Music öffnen", systemImage: "arrow.up.right.square")
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                    .padding(.horizontal)
                }

                if let onExploreArtist {
                    Button {
                        dismiss()
                        onExploreArtist(track.artistName)
                    } label: {
                        Label {
                            Text("Mehr von \(track.artistName)")
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        } icon: {
                            Image(systemName: "magnifyingglass")
                        }
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                    .padding(.horizontal)
                }

                Spacer(minLength: 12)
            }
            .padding(.bottom, 20)
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Fertig") {
                    dismiss()
                }
            }
        }
        .task {
            let store = LikedTracksStore(context: modelContext)
            likesStore = store
            isLiked = store.isLiked(trackId: track.id)
        }
    }

    private func toggleLike() {
        let store = likesStore ?? LikedTracksStore(context: modelContext)
        if isLiked {
            store.unlike(trackId: track.id)
            isLiked = false
        } else {
            store.like(track)
            isLiked = true
        }
    }
}
