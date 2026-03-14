import SwiftUI
import SwiftData
import Combine

struct TrackDetailView: View {
    let track: Track
    @ObservedObject var audio: AudioPlayerService

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var toastManager: ToastManager

    @State private var likesStore: LikedTracksStore?
    @State private var likedIds: Set<Int> = []
    @State private var playlistsStore: PlaylistStore?
    @State private var playlists: [PlaylistEntity] = []
    @State private var showingAddToPlaylistSheet = false
    @State private var showingCreatePlaylistAlert = false
    @State private var newPlaylistName = ""
    let onOpenArtist: (String) -> Void

    init(
        track: Track,
        audio: AudioPlayerService,
        onOpenArtist: @escaping (String) -> Void
    ) {
        self.track = track
        self.audio = audio
        self.onOpenArtist = onOpenArtist
    }

    private var isCurrentTrackPlaying: Bool {
        audio.state == .playing && audio.nowPlayingTrack?.id == track.id
    }

    private var isCurrentTrackSelected: Bool {
        audio.nowPlayingTrack?.id == track.id
    }

    private var isLiked: Bool {
        likedIds.contains(track.id)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                AsyncArtworkImage(url: track.artworkURL)
                    .frame(width: 260, height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
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
                            isCurrentTrackPlaying ? "Pausieren" : "Abspielen",
                            systemImage: isCurrentTrackPlaying ? "pause.fill" : "play.fill"
                        )
                        .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(track.previewURL == nil)
                    .accessibilityLabel(isCurrentTrackPlaying ? "Vorschau pausieren" : "Vorschau abspielen")
                    .accessibilityHint(track.previewURL == nil ? "Für diesen Track ist keine Vorschau verfügbar" : "Spielt eine 30 Sekunden Vorschau ab")

                    Button {
                        audio.stop()
                    } label: {
                        Label("Stoppen", systemImage: "stop.fill")
                            .frame(minWidth: 88, minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                    .disabled(audio.state == .stopped || !isCurrentTrackSelected)
                    .accessibilityLabel("Vorschau stoppen")

                    Button {
                        toggleLike()
                    } label: {
                        Label(isLiked ? "Favorisiert" : "Zu Favoriten", systemImage: isLiked ? "heart.fill" : "heart")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel(isLiked ? "Aus Favoriten entfernen" : "Zu Favoriten hinzufügen")
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
                    .accessibilityHint("Öffnet den Track in Apple Music")
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
                .accessibilityHint("Öffnet eine Playlist-Auswahl")

                Button {
                    dismiss()
                    DispatchQueue.main.async {
                        onOpenArtist(track.artistName)
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
                .accessibilityHint("Startet eine Artist-Suche in Explore")

                Spacer(minLength: 12)
            }
            .padding(.bottom, 20)
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) {
            toastOverlay(bottomPadding: 12)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Fertig") {
                    dismiss()
                }
                .accessibilityLabel("Details schließen")
            }
        }
        .task {
            let store = LikedTracksStore(context: modelContext)
            likesStore = store
            likedIds = store.likedIds
            if playlistsStore == nil {
                playlistsStore = PlaylistStore(context: modelContext)
            }
        }
        .onReceive(likedIdsPublisher) { ids in
            likedIds = ids
        }
        .onChange(of: showingAddToPlaylistSheet) { _, isPresented in
            if isPresented {
                loadPlaylists()
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
                            .accessibilityHint("Öffnet den Dialog zum Erstellen einer Playlist")
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

                                    if playlist.tracks.contains(where: { $0.trackId == track.id }) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(playlist.name)
                            .accessibilityHint("Fügt den Track zu dieser Playlist hinzu oder entfernt ihn daraus")
                        }
                    }
                }
                .navigationTitle("Playlists")
                .navigationBarTitleDisplayMode(.inline)
                .overlay(alignment: .bottom) {
                    toastOverlay(bottomPadding: 12)
                }
                .onAppear {
                    loadPlaylists()
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Schließen") {
                            showingAddToPlaylistSheet = false
                        }
                        .accessibilityLabel("Playlist-Auswahl schließen")
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
        likesStore = store
        if isLiked {
            store.unlike(trackId: track.id)
            toastManager.show("Aus Favoriten entfernt", icon: "heart.slash")
        } else {
            store.like(track)
            toastManager.show("Zu Favoriten hinzugefügt", icon: "heart.fill")
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
        if playlist.tracks.contains(where: { $0.trackId == track.id }) {
            store.removeTrack(from: playlist.id, trackId: track.id)
            toastManager.show("Aus Playlist entfernt", icon: "minus.circle")
        } else {
            store.addTrack(to: playlist.id, track: track)
            toastManager.show("Zur Playlist hinzugefügt", icon: "checkmark.circle")
        }
    }

    private func createPlaylistFromSheet() {
        let trimmed = newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if playlistsStore == nil {
            playlistsStore = PlaylistStore(context: modelContext)
        }
        guard let store = playlistsStore else { return }
        let createdPlaylist = store.createPlaylist(name: trimmed)
        if !playlists.contains(where: { $0.id == createdPlaylist.id }) {
            playlists.insert(createdPlaylist, at: 0)
        }
        newPlaylistName = ""
        showingCreatePlaylistAlert = false
        toastManager.show("Playlist erstellt", icon: "checkmark.circle")
    }

    @ViewBuilder
    private func toastOverlay(bottomPadding: CGFloat) -> some View {
        if let toast = toastManager.toast {
            ToastView(toast: toast)
                .padding(.horizontal, 12)
                .padding(.bottom, bottomPadding)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
    }

    private var likedIdsPublisher: AnyPublisher<Set<Int>, Never> {
        if let likesStore {
            return likesStore.$likedIds.eraseToAnyPublisher()
        }
        return Just(likedIds).eraseToAnyPublisher()
    }
}
