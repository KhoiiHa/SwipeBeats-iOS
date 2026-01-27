import SwiftUI
import SwiftData

struct TrackDetailView: View {
    let track: Track
    @ObservedObject var audio: AudioPlayerService

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL

    @State private var isLiked = false
    let onExploreArtist: ((String) -> Void)?

    private var store: LikedTracksStore {
        LikedTracksStore(context: modelContext)
    }

    init(
        track: Track,
        audio: AudioPlayerService,
        onExploreArtist: ((String) -> Void)? = nil
    ) {
        self.track = track
        self.audio = audio
        self.onExploreArtist = onExploreArtist
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                AsyncArtworkImage(url: track.artworkURL)
                    .frame(width: 260, height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .shadow(radius: 12)
                    .padding(.top, 8)

                VStack(spacing: 6) {
                    Text(track.trackName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)

                    Text(track.artistName)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                HStack(spacing: 12) {
                    Button {
                        audio.toggle(url: track.previewURL)
                    } label: {
                        Label(
                            audio.state == .playing ? "Pause" : "Play",
                            systemImage: audio.state == .playing ? "pause.fill" : "play.fill"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(track.previewURL == nil)

                    Button {
                        toggleLike()
                    } label: {
                        Label(isLiked ? "Liked" : "Like", systemImage: isLiked ? "heart.fill" : "heart")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)

                if let url = track.collectionViewURL {
                    Button {
                        openURL(url)
                    } label: {
                        Label("In Apple Music öffnen", systemImage: "arrow.up.right.square")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                    .padding(.horizontal)
                }

                Button {
                    // Close the detail view and trigger an Explore search (if provided)
                    dismiss()
                    onExploreArtist?(track.artistName)
                } label: {
                    Label {
                        Text("Mehr von \(track.artistName)")
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    } icon: {
                        Image(systemName: "magnifyingglass")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)

                Spacer(minLength: 12)
            }
            .padding(.bottom, 20)
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Fertig") { dismiss() }
            }
        }
        .task {
            isLiked = store.isLiked(trackId: track.id)
        }
    }

    private func toggleLike() {
        if isLiked {
            store.unlike(trackId: track.id)
            isLiked = false
        } else {
            store.like(track)
            isLiked = true
        }
    }
}
