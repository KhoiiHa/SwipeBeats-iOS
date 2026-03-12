import SwiftUI
import SwiftData

struct PlaylistsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var toastManager: ToastManager

    @State private var store: PlaylistStore?
    @State private var playlists: [PlaylistEntity] = []
    @State private var showingCreateSheet = false
    @State private var newPlaylistName = ""

    var body: some View {
        Group {
            if playlists.isEmpty {
                ContentUnavailableView(
                    "Keine Playlists",
                    systemImage: "music.note.list",
                    description: Text("Erstelle deine erste Playlist.")
                )
            } else {
                List {
                    ForEach(playlists, id: \.id) { playlist in
                        NavigationLink {
                            PlaylistDetailView(playlist: playlist)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(playlist.name)
                                    .font(.headline)
                                    .lineLimit(1)

                                Text(playlist.createdAt, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete(perform: deletePlaylists)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    newPlaylistName = ""
                    showingCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Playlist erstellen")
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            NavigationStack {
                Form {
                    TextField("Playlist-Name", text: $newPlaylistName)
                        .textInputAutocapitalization(.words)
                }
                .navigationTitle("Neue Playlist")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") {
                            showingCreateSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Erstellen") {
                            createPlaylist()
                        }
                        .disabled(trimmedNewPlaylistName.isEmpty)
                    }
                }
            }
        }
        .onAppear {
            ensureStore()
            reloadPlaylists()
        }
    }

    private var trimmedNewPlaylistName: String {
        newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func ensureStore() {
        if store == nil {
            store = PlaylistStore(context: modelContext)
        }
    }

    private func reloadPlaylists() {
        ensureStore()
        playlists = store?.fetchPlaylists() ?? []
    }

    private func createPlaylist() {
        ensureStore()
        _ = store?.createPlaylist(name: trimmedNewPlaylistName)
        showingCreateSheet = false
        reloadPlaylists()
        toastManager.show("Playlist erstellt", icon: "checkmark.circle")
    }

    private func deletePlaylists(at offsets: IndexSet) {
        ensureStore()
        guard let store else { return }
        for index in offsets {
            store.deletePlaylist(id: playlists[index].id)
        }
        reloadPlaylists()
        if !offsets.isEmpty {
            toastManager.show("Playlist gelöscht", icon: "trash")
        }
    }
}
