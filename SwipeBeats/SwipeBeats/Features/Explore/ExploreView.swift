import SwiftUI

struct ExploreView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var audio: AudioPlayerService
    @EnvironmentObject private var toastManager: ToastManager

    @ObservedObject var viewModel: ExploreViewModel

    @State private var selectedPresetId: String? = Constants.defaultSearchPresetId
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
        .task {
            if viewModel.consumeAutomaticPresetLoadSuppression() {
                return
            }

            guard viewModel.lastSearchedTerm.isEmpty else { return }
            guard let selectedPresetId,
                  let preset = Constants.searchPresets.first(where: { $0.id == selectedPresetId }) else { return }

            await viewModel.loadPreset(preset, presetId: selectedPresetId)
        }
        .onChange(of: selectedPresetId) { oldValue, newValue in
            guard oldValue != newValue else { return }
            guard let newValue,
                  let preset = Constants.searchPresets.first(where: { $0.id == newValue }) else { return }

            Task {
                await viewModel.loadPreset(preset, presetId: newValue)
            }
        }
        .onChange(of: viewModel.currentSearchContext) { _, context in
            switch context {
            case .preset(let presetId):
                if selectedPresetId != presetId {
                    selectedPresetId = presetId
                }
            case .manual, .externalArtist:
                if selectedPresetId != nil {
                    selectedPresetId = nil
                }
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
                    onOpenArtist: { artistName in
                        selectedTrack = nil
                        Task { await viewModel.runExternalArtistSearch(artistName) }
                    }
                )
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                TextField("Künstler, Song, Genre…", text: $viewModel.query)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit { Task { await viewModel.searchCurrentQuery() } }

                if !viewModel.query.isEmpty {
                    Button {
                        viewModel.query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Suche leeren")
                }

                Button {
                    Task { await viewModel.searchCurrentQuery() }
                } label: {
                    Image(systemName: "magnifyingglass")
                }
                .buttonStyle(.bordered)
                .tint(.teal)
                .disabled(viewModel.state == .loading || viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Picker("Preset", selection: $selectedPresetId) {
                Text("Kein Preset").tag(String?.none)
                ForEach(Constants.searchPresets) { preset in
                    Text(preset.title).tag(Optional(preset.id))
                }
            }
            .pickerStyle(.menu)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Toggle("Nur mit Vorschau", isOn: $viewModel.onlyWithPreview)
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

                HStack(spacing: 12) {
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

                    Spacer()

                    Button {
                        switch viewModel.currentSearchContext {
                        case .preset(let presetId):
                            guard let preset = Constants.searchPresets.first(where: { $0.id == presetId }) else {
                                Task { await viewModel.searchCurrentQuery(forceKeyword: false) }
                                return
                            }
                            Task { await viewModel.loadPreset(preset, presetId: presetId) }
                        case .manual, .externalArtist:
                            Task { await viewModel.searchCurrentQuery(forceKeyword: false) }
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .tint(.teal)
                    .disabled(viewModel.state == .loading)
                }
            }
            .font(.subheadline)
            .padding(12)
            .padding(.top, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 6, y: 2)

            if !viewModel.recentSearches.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Letzte Suchen")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            viewModel.clearHistory()
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Verlauf löschen")
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.recentSearches, id: \.self) { term in
                                Button {
                                    Task { await viewModel.useRecent(term) }
                                } label: {
                                    Text(term)
                                        .font(.subheadline)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        .minimumScaleFactor(0.9)
                                        .frame(maxWidth: 220, alignment: .leading)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(.secondary.opacity(0.12), in: Capsule())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Letzte Suche: \(term)")
                                .accessibilityHint("Führt diese Suche erneut aus")
                            }
                        }
                    }
                }
            }
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
                description: Text("Preset wählen oder Begriff eingeben.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .loading:
                ProgressView("Lade Tracks…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .empty:
            ContentUnavailableView(
                "Keine Treffer",
                systemImage: "music.note",
                description: Text("Bitte anderen Begriff versuchen.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .error(let message):
                VStack(spacing: 12) {
                    ContentUnavailableView(
                        "Fehler",
                        systemImage: "exclamationmark.triangle",
                        description: Text(message.isEmpty ? "Bitte erneut versuchen." : message)
                    )
                Button("Erneut versuchen") {
                    Task { await viewModel.searchCurrentQuery(forceKeyword: false) }
                }
                .buttonStyle(.borderedProminent)
                .tint(.teal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .content:
            List {
                ForEach(viewModel.results) { track in
                    let isLiked = viewModel.isLiked(trackId: track.id)
                    Button {
                        audio.setNowPlaying(track: track)
                        selectedTrack = track
                    } label: {
                        TrackRowView(track: track)
                            .padding(.vertical, 3)
                    }
                        .buttonStyle(.plain)
                        .accessibilityHint("Öffnet die Track-Details")
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button {
                                toggleLike(track, isLiked: isLiked)
                            } label: {
                                if isLiked {
                                    Label("Aus Favoriten entfernen", systemImage: "heart.slash")
                                } else {
                                    Label("Zu Favoriten hinzufügen", systemImage: "heart")
                                }
                            }
                            .tint(isLiked ? .secondary : .pink)

                            if let url = track.collectionViewURL {
                                Button {
                                    openURL(url)
                                } label: {
                                    Label("In Apple Music öffnen", systemImage: "arrow.up.right.square")
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
                                toggleLike(track, isLiked: isLiked)
                            } label: {
                                if isLiked {
                                    Label("Aus Favoriten entfernen", systemImage: "heart.slash")
                                } else {
                                    Label("Zu Favoriten hinzufügen", systemImage: "heart")
                                }
                            }

                            if let url = track.collectionViewURL {
                                Button {
                                    openURL(url)
                                } label: {
                                    Label("In Apple Music öffnen", systemImage: "arrow.up.right.square")
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .listRowSeparatorTint(.secondary.opacity(0.18))
                .refreshable {
                    await viewModel.searchCurrentQuery(forceKeyword: false)
                }
            }
        }
    }

    private func toggleLike(_ track: Track, isLiked: Bool) {
        if isLiked {
            viewModel.unlike(trackId: track.id)
            toastManager.show("Aus Favoriten entfernt", icon: "heart.slash")
        } else {
            viewModel.like(track)
            toastManager.show("Zu Favoriten hinzugefügt", icon: "heart.fill")
        }
    }
}
