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
                if playlist.trackIds.isEmpty {
                    ContentUnavailableView(
                        "Leere Playlist",
                        systemImage: "music.note",
                        description: Text("Diese Playlist enthält noch keine Tracks.")
                    )
                } else {
                    List(playlist.trackIds, id: \.self) { trackId in
                        Text("Track-ID \(trackId)")
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
}
