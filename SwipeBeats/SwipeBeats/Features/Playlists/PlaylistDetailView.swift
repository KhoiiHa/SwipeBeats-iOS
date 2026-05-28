import SwiftUI
import SwiftData

struct PlaylistDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var audio: AudioPlayerService
    @EnvironmentObject private var toastManager: ToastManager

    let playlist: PlaylistEntity

    @State private var store: PlaylistStore?
    @State private var renameText = ""
    @State private var showingRenameAlert = false

    var body: some View {
        Group {
            if playlist.tracks.isEmpty {
                ContentUnavailableView(
                    "Leere Playlist",
                    systemImage: "music.note",
                    description: Text("Diese Playlist enthält noch keine Tracks.")
                )
            } else {
                VStack(spacing: 12) {
                    playlistSummary
                        .padding(.horizontal)

                    Button {
                        playPlaylist(in: playlist)
                    } label: {
                        Label("Playlist abspielen", systemImage: "play.fill")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.teal)
                    .disabled(firstPlayableTrack(in: playlist) == nil)
                    .padding(.horizontal)
                    .accessibilityLabel("Playlist abspielen")
                    .accessibilityHint("Startet den ersten abspielbaren Track der Playlist")

                    List {
                        ForEach(playlist.tracks) { snapshot in
                            Button {
                                playPlaylist(in: playlist, startingAt: snapshot)
                            } label: {
                                row(for: snapshot)
                            }
                            .buttonStyle(.plain)
                            .disabled(!isPlayable(snapshot))
                            .accessibilityLabel("\(snapshot.title) von \(snapshot.artist)")
                            .accessibilityHint(isPlayable(snapshot) ? "Spielt die Playlist ab diesem Track ab" : "Keine Vorschau verfügbar")
                        }
                        .onDelete(perform: removeTracks)
                    }
                }
            }
        }
        .navigationTitle(playlist.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Umbenennen") {
                    renameText = playlist.name
                    showingRenameAlert = true
                }
                .accessibilityLabel("Playlist umbenennen")
            }
        }
        .alert("Playlist umbenennen", isPresented: $showingRenameAlert) {
            TextField("Name", text: $renameText)
            Button("Abbrechen", role: .cancel) {}
            Button("Speichern") {
                renamePlaylist()
            }
            .disabled(renameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .onAppear {
            ensureStore()
        }
    }

    private var playlistSummary: some View {
        let playableCount = playableTracks(in: playlist).count
        let totalCount = playlist.tracks.count

        return HStack(spacing: 8) {
            Image(systemName: "music.note.list")
                .foregroundStyle(.teal)

            Text("\(playableCount) von \(totalCount) Tracks spielbar")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func ensureStore() {
        if store == nil {
            store = PlaylistStore(context: modelContext)
        }
    }

    private func renamePlaylist() {
        let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        ensureStore()
        store?.renamePlaylist(id: playlist.id, newName: trimmed)
        toastManager.show("Playlist umbenannt", icon: "pencil")
    }

    private func removeTracks(at offsets: IndexSet) {
        guard let store else { return }
        for index in offsets {
            let snapshot = playlist.tracks[index]
            store.removeTrack(from: playlist.id, trackId: snapshot.trackId)
        }
        if !offsets.isEmpty {
            toastManager.show("Aus Playlist entfernt", icon: "minus.circle")
        }
    }

    private func row(for snapshot: PlaylistTrackSnapshot) -> some View {
        let isCurrentTrack = isCurrent(snapshot)
        let isPlayableTrack = isPlayable(snapshot)

        return HStack(spacing: 12) {
            artwork(for: snapshot)
                .frame(width: 58, height: 58)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    if isCurrentTrack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(.teal, lineWidth: 2)
                    }
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(snapshot.title)
                    .font(.headline)
                    .foregroundStyle(isCurrentTrack ? .teal : .primary)
                    .lineLimit(1)

                Text(snapshot.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if isCurrentTrack {
                    Label(audio.isPlaying ? "Spielt gerade" : "Aktueller Track", systemImage: audio.isPlaying ? "speaker.wave.2.fill" : "pause.fill")
                        .font(.caption)
                        .foregroundStyle(.teal)
                } else if !isPlayableTrack {
                    Label("Keine Vorschau", systemImage: "speaker.slash.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: isCurrentTrack ? "speaker.wave.2.fill" : "play.fill")
                .font(.caption)
                .foregroundStyle(isCurrentTrack ? .teal : .secondary)
                .opacity(isPlayableTrack ? 1 : 0.3)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .opacity(isPlayableTrack ? 1 : 0.6)
    }

    @ViewBuilder
    private func artwork(for snapshot: PlaylistTrackSnapshot) -> some View {
        if let artworkUrl = snapshot.artworkUrl, let url = URL(string: artworkUrl) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    placeholderArtwork
                @unknown default:
                    placeholderArtwork
                }
            }
        } else {
            placeholderArtwork
        }
    }

    private var placeholderArtwork: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(.secondary.opacity(0.2))
            .overlay {
                Image(systemName: "music.note")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
    }

    private func makeTrack(from snapshot: PlaylistTrackSnapshot) -> Track? {
        guard let previewURLString = snapshot.previewURL,
              let previewURL = URL(string: previewURLString) else { return nil }

        return Track(
            id: snapshot.trackId,
            artistName: snapshot.artist,
            trackName: snapshot.title,
            artworkURL: snapshot.artworkUrl.flatMap(URL.init(string:)),
            previewURL: previewURL,
            collectionViewURL: nil,
            primaryGenreName: nil
        )
    }

    private func firstPlayableTrack(in playlist: PlaylistEntity) -> PlaylistTrackSnapshot? {
        playlist.tracks.first { snapshot in
            isPlayable(snapshot)
        }
    }

    private func playableTracks(in playlist: PlaylistEntity) -> [Track] {
        playlist.tracks.compactMap(makeTrack)
    }

    private func playPlaylist(in playlist: PlaylistEntity, startingAt snapshot: PlaylistTrackSnapshot? = nil) {
        let tracks = playableTracks(in: playlist)
        guard !tracks.isEmpty else { return }

        let startIndex: Int
        if let snapshot,
           let index = tracks.firstIndex(where: { $0.id == snapshot.trackId }) {
            startIndex = index
        } else {
            startIndex = 0
        }

        audio.playQueue(tracks, startAt: startIndex)
    }

    private func isPlayable(_ snapshot: PlaylistTrackSnapshot) -> Bool {
        guard let previewURL = snapshot.previewURL else { return false }
        return URL(string: previewURL) != nil
    }

    private func isCurrent(_ snapshot: PlaylistTrackSnapshot) -> Bool {
        audio.nowPlayingTrack?.id == snapshot.trackId
    }
}
