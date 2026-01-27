import SwiftUI

struct ExploreView: View {
    @StateObject private var viewModel = ExploreViewModel()
    @StateObject private var audio = AudioPlayerService()

    @State private var selectedTerm: String = Constants.defaultSearchTerm

    var body: some View {
        VStack(spacing: 12) {
            header

            content
        }
        .padding(.top, 8)
        .task(id: selectedTerm) {
            await viewModel.loadPreset(term: selectedTerm)
        }
        .onChange(of: viewModel.onlyWithPreview) { _, _ in
            Task { await viewModel.searchCurrentQuery() }
        }
        .onChange(of: viewModel.limit) { _, _ in
            Task { await viewModel.searchCurrentQuery() }
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
                Picker("Preset", selection: $selectedTerm) {
                    ForEach(Constants.searchPresets) { preset in
                        Text(preset.title).tag(preset.term)
                    }
                }
                .pickerStyle(.menu)

                Button {
                    Task { await viewModel.loadPreset(term: selectedTerm) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.state == .loading)
            }

            HStack(spacing: 12) {
                Toggle("Nur mit Preview", isOn: $viewModel.onlyWithPreview)

                Picker("Limit", selection: $viewModel.limit) {
                    Text("25").tag(25)
                    Text("50").tag(50)
                }
                .pickerStyle(.segmented)
                .frame(width: 140)
            }
            .font(.subheadline)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            ContentUnavailableView(
                "Suche starten",
                systemImage: "magnifyingglass",
                description: Text("Wähle ein Preset oder suche nach einem Begriff.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .loading:
            ProgressView("Lade Tracks…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .empty:
            ContentUnavailableView(
                "Keine Treffer",
                systemImage: "music.note",
                description: Text("Versuche einen anderen Begriff.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .error(let message):
            VStack(spacing: 12) {
                ContentUnavailableView(
                    "Fehler",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
                Button("Erneut versuchen") {
                    Task { await viewModel.searchCurrentQuery() }
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .content:
            List {
                ForEach(viewModel.results) { track in
                    NavigationLink {
                        TrackDetailView(track: track, audio: audio)
                    } label: {
                        TrackRowView(track: track)
                    }
                }
            }
            .listStyle(.plain)
            .refreshable {
                await viewModel.searchCurrentQuery()
            }
        }
    }
}
