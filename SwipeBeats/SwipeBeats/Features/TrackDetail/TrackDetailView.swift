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
    @State private var playlistsStore: PlaylistStore?
    @State private var playlists: [PlaylistEntity] = []
    @State private var showingAddToPlaylistSheet = false
    @State private var showingCreatePlaylistAlert = false
    @State private var newPlaylistName = ""
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
        audio.state == .playing && audio.nowPlayingTrack?.id == track.id
    }

    private var isCurrentTrackSelected: Bool {
        audio.nowPlayingTrack?.id == track.id
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
                    .disabled(audio.state == .stopped || !isCurrentTrackSelected)
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

                Button {
                    loadPlaylists()
                    showingAddToPlaylistSheet = true
                } label: {
                    Label("Zu Playlist hinzufügen", systemImage: "text.badge.plus")
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)

                Button {
                    dismiss()
                    if let onExploreArtist {
                        onExploreArtist(track.artistName)
                    } else {
                        NotificationCenter.default.post(
                            name: .openExploreArtist,
                            object: nil,
                            userInfo: ["artistName": track.artistName]
                        )
                    }
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
            if playlistsStore == nil {
                playlistsStore = PlaylistStore(context: modelContext)
            }
        }
        .sheet(isPresented: $showingAddToPlaylistSheet) {
            NavigationStack {
                Group {
                    if playlists.isEmpty {
                        VStack(spacing: 12) {
                            ContentUnavailableView(
                                "Keine Playlists",
                                systemImage: "music.note.list",
                                description: Text("Keine Playlists – erstelle eine neue.")
                            )

                            Button("Neue Playlist erstellen") {
                                newPlaylistName = ""
                                showingCreatePlaylistAlert = true
                            }
                            .buttonStyle(.borderedProminent)
                            .frame(minHeight: 44)
                        }
                    } else {
                        List(playlists, id: \.id) { playlist in
                            Button {
                                toggleTrack(in: playlist)
                                showingAddToPlaylistSheet = false
                            } label: {
                                HStack(spacing: 12) {
                                    Text(playlist.name)
                                        .lineLimit(1)
                                        .truncationMode(.tail)

                                    Spacer()

                                    if playlist.trackIds.contains(track.id) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .navigationTitle("Playlists")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Schließen") {
                            showingAddToPlaylistSheet = false
                        }
                    }
                }
                .alert("Neue Playlist", isPresented: $showingCreatePlaylistAlert) {
                    TextField("Name", text: $newPlaylistName)
                    Button("Abbrechen", role: .cancel) {}
                    Button("Erstellen") {
                        createPlaylistFromSheet()
                    }
                    .disabled(newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
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

    private func loadPlaylists() {
        if playlistsStore == nil {
            playlistsStore = PlaylistStore(context: modelContext)
        }
        playlists = playlistsStore?.fetchPlaylists() ?? []
    }

    private func toggleTrack(in playlist: PlaylistEntity) {
        guard let store = playlistsStore else { return }
        if playlist.trackIds.contains(track.id) {
            store.removeTrack(from: playlist.id, trackId: track.id)
        } else {
            store.addTrack(to: playlist.id, track: track)
        }
    }

    private func createPlaylistFromSheet() {
        let trimmed = newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if playlistsStore == nil {
            playlistsStore = PlaylistStore(context: modelContext)
        }
        _ = playlistsStore?.createPlaylist(name: trimmed)
        loadPlaylists()
        showingCreatePlaylistAlert = false
    }
}
