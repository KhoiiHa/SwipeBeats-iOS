import SwiftUI
import SwiftData

struct PlaylistDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let playlistId: UUID

    @State private var store: PlaylistStore?
    @State private var playlist: PlaylistEntity?
    @State private var renameText = ""
    @State private var showingRenameAlert = false

    var body: some View {
        Group {
            if let playlist {
                if playlist.tracks.isEmpty {
                    ContentUnavailableView(
                        "Leere Playlist",
                        systemImage: "music.note",
                        description: Text("Diese Playlist enthält noch keine Tracks.")
                    )
                } else {
                    List {
                        ForEach(playlist.tracks) { snapshot in
                            row(for: snapshot)
                        }
                        .onDelete(perform: removeTracks)
                    }
                }
            } else {
                ContentUnavailableView(
                    "Playlist nicht gefunden",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Bitte gehe zurück und versuche es erneut.")
                )
            }
        }
        .navigationTitle(playlist?.name ?? "Playlist")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Umbenennen") {
                    renameText = playlist?.name ?? ""
                    showingRenameAlert = true
                }
                .disabled(playlist == nil)
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
            loadPlaylist()
        }
    }

    private func ensureStore() {
        if store == nil {
            store = PlaylistStore(context: modelContext)
        }
    }

    private func loadPlaylist() {
        ensureStore()
        playlist = store?.fetchPlaylists().first(where: { $0.id == playlistId })
    }

    private func renamePlaylist() {
        let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        ensureStore()
        store?.renamePlaylist(id: playlistId, newName: trimmed)
        loadPlaylist()
    }

    private func removeTracks(at offsets: IndexSet) {
        guard let playlist, let store else { return }
        for index in offsets {
            let snapshot = playlist.tracks[index]
            store.removeTrack(from: playlist.id, trackId: snapshot.trackId)
        }
        loadPlaylist()
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
        }
        .padding(.vertical, 4)
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
}
