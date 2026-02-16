import SwiftUI

struct ExploreView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var audio: AudioPlayerService

    @StateObject private var viewModel = ExploreViewModel()

    @State private var selectedPresetId: String = Constants.defaultSearchPresetId
    @State private var selectedTrack: Track?

    var body: some View {
        VStack(spacing: 12) {
            header

            content
        }
        .padding(.top, 8)
        .task {
            viewModel.configureLikesStore(context: modelContext)
        }
        .task(id: selectedPresetId) {
            if let preset = Constants.searchPresets.first(where: { $0.id == selectedPresetId }) {
                await viewModel.loadPreset(preset)
            } else {
                await viewModel.searchCurrentQuery()
            }
        }
        .onChange(of: viewModel.onlyWithPreview) { _, _ in
            viewModel.applyFilters()
        }
        .onChange(of: viewModel.sortOption) { _, _ in
            viewModel.applyFilters()
        }
        .onChange(of: viewModel.limit) { _, _ in
            Task { await viewModel.searchCurrentQuery(forceKeyword: false) }
        }
        .sheet(item: $selectedTrack) { track in
            NavigationStack {
                TrackDetailView(
                    track: track,
                    audio: audio,
                    onExploreArtist: { artistName in
                        // Close the sheet and run a new Explore search for the artist
                        selectedTrack = nil
                        viewModel.query = artistName
                        Task { await viewModel.searchCurrentQuery() }
                    }
                )
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                TextField("Künstler, Song, Genre…", text: $viewModel.query)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit { Task { await viewModel.searchCurrentQuery() } }

                Button {
                    Task { await viewModel.searchCurrentQuery() }
                } label: {
                    Image(systemName: "magnifyingglass")
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.state == .loading || viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            HStack(spacing: 12) {
                Picker("Preset", selection: $selectedPresetId) {
                    ForEach(Constants.searchPresets) { preset in
                        Text(preset.title).tag(preset.id)
                    }
                }
                .pickerStyle(.menu)

                Button {
                    guard let preset = Constants.searchPresets.first(where: { $0.id == selectedPresetId }) else {
                        Task { await viewModel.searchCurrentQuery() }
                        return
                    }
                    Task { await viewModel.loadPreset(preset) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.state == .loading)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Toggle("Nur mit Preview", isOn: $viewModel.onlyWithPreview)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)

                    Spacer(minLength: 8)

                    Picker("Sort", selection: $viewModel.sortOption) {
                        ForEach(ExploreViewModel.SortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                }

                HStack {
                    Text("Limit")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Picker("Limit", selection: $viewModel.limit) {
                        Text("25").tag(25)
                        Text("50").tag(50)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 140)
                }
            }
            .font(.subheadline)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var content: some View {
        Group {
            switch viewModel.state {
        case .idle:
            ContentUnavailableView(
                "Suche starten",
                systemImage: "magnifyingglass",
                description: Text("Wähle ein Preset oder gib einen Suchbegriff ein.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .loading:
                ProgressView("Lade Tracks…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .empty:
            ContentUnavailableView(
                "Keine Treffer",
                systemImage: "music.note",
                description: Text("Keine passenden Songs gefunden. Probiere einen anderen Begriff.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .error(let message):
                VStack(spacing: 12) {
                    ContentUnavailableView(
                        "Laden fehlgeschlagen",
                        systemImage: "exclamationmark.triangle",
                        description: Text(message)
                    )
                Button("Erneut versuchen") {
                    Task { await viewModel.searchCurrentQuery(forceKeyword: false) }
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .content:
            List {
                if !viewModel.recentSearches.isEmpty {
                    Section {
                        ForEach(viewModel.recentSearches, id: \.self) { term in
                            Button {
                                Task { await viewModel.useRecent(term) }
                            } label: {
                                HStack {
                                    Text(term)
                                        .font(.subheadline)
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        HStack {
                            Text("Letzte Suchen")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("Verlauf löschen") {
                                viewModel.clearHistory()
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .buttonStyle(.plain)
                        }
                    } footer: {
                        Divider()
                    }
                }
                ForEach(viewModel.results) { track in
                    let isLiked = viewModel.isLiked(trackId: track.id)
                    Button {
                        audio.setNowPlaying(track: track)
                        selectedTrack = track
                    } label: {
                        TrackRowView(track: track)
                            .padding(.vertical, 4)
                    }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button {
                                if isLiked {
                                    viewModel.unlike(trackId: track.id)
                                } else {
                                    viewModel.like(track)
                                }
                            } label: {
                                if isLiked {
                                    Label("Like entfernen", systemImage: "heart.slash")
                                } else {
                                    Label("Like", systemImage: "heart")
                                }
                            }
                            .tint(isLiked ? .gray : .pink)

                            if let url = track.collectionViewURL {
                                Button {
                                    openURL(url)
                                } label: {
                                    Label("Apple Music", systemImage: "arrow.up.right.square")
                                }
                                .tint(.blue)
                            }
                        }
                        .contextMenu {
                            Button {
                                selectedTrack = track
                            } label: {
                                Label("Details", systemImage: "info.circle")
                            }

                            Button {
                                if isLiked {
                                    viewModel.unlike(trackId: track.id)
                                } else {
                                    viewModel.like(track)
                                }
                            } label: {
                                if isLiked {
                                    Label("Like entfernen", systemImage: "heart.slash")
                                } else {
                                    Label("Like", systemImage: "heart")
                                }
                            }

                            if let url = track.collectionViewURL {
                                Button {
                                    openURL(url)
                                } label: {
                                    Label("Apple Music", systemImage: "arrow.up.right.square")
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await viewModel.searchCurrentQuery(forceKeyword: false)
                }
            }
        }
    }
}
