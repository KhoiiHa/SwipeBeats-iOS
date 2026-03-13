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
                    Button {
                        playFirstAvailableTrack(in: playlist)
                    } label: {
                        Label("Playlist abspielen", systemImage: "play.fill")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(firstPlayableTrack(in: playlist) == nil)
                    .padding(.horizontal)
                    .accessibilityLabel("Playlist abspielen")
                    .accessibilityHint("Startet den ersten abspielbaren Track der Playlist")

                    List {
                        ForEach(playlist.tracks) { snapshot in
                            Button {
                                play(snapshot)
                            } label: {
                                row(for: snapshot)
                            }
                            .buttonStyle(.plain)
                            .disabled(snapshot.previewURL == nil)
                            .accessibilityLabel("\(snapshot.title) von \(snapshot.artist)")
                            .accessibilityHint(snapshot.previewURL == nil ? "Keine Vorschau verfügbar" : "Spielt die Vorschau dieses Tracks ab")
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
        HStack(spacing: 12) {
            artwork(for: snapshot)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(snapshot.title)
                    .font(.headline)
                    .lineLimit(1)

                Text(snapshot.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "play.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
                .opacity(snapshot.previewURL == nil ? 0.3 : 1)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .opacity(snapshot.previewURL == nil ? 0.6 : 1)
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
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(.secondary.opacity(0.2))
            .overlay {
                Image(systemName: "music.note")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
    }

    private func play(_ snapshot: PlaylistTrackSnapshot) {
        guard let previewURLString = snapshot.previewURL,
              let previewURL = URL(string: previewURLString) else { return }

        let track = Track(
            id: snapshot.trackId,
            artistName: snapshot.artist,
            trackName: snapshot.title,
            artworkURL: snapshot.artworkUrl.flatMap(URL.init(string:)),
            previewURL: previewURL,
            collectionViewURL: nil,
            primaryGenreName: nil
        )

        audio.setNowPlaying(track: track)
        audio.toggle(url: previewURL)
    }

    private func firstPlayableTrack(in playlist: PlaylistEntity) -> PlaylistTrackSnapshot? {
        playlist.tracks.first { snapshot in
            guard let previewURL = snapshot.previewURL else { return false }
            return URL(string: previewURL) != nil
        }
    }

    private func playFirstAvailableTrack(in playlist: PlaylistEntity) {
        guard let snapshot = firstPlayableTrack(in: playlist) else { return }
        play(snapshot)
    }
}
