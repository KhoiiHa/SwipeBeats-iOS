import SwiftUI
import SwiftData

struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var audio = AudioPlayerService()
    @StateObject private var exploreViewModel = ExploreViewModel()
    @StateObject private var toastManager = ToastManager()
    @State private var nowPlayingDetailTrack: Track?
    @State private var swipeViewModel: SwipeViewModel?
    @State private var selectedTab: AppTab = .swipe
    private let di = AppDIContainer()
    private let miniPlayerReservedHeight: CGFloat = 62
    private let tabBarHeight: CGFloat = 49

    var body: some View {
        GeometryReader { geometry in
            TabView(selection: $selectedTab) {
                NavigationStack {
                    Group {
                        if let swipeViewModel {
                            SwipeView(
                                viewModel: swipeViewModel,
                                onOpenArtistInExplore: openArtistInExplore
                            )
                        } else {
                            ProgressView("Lade Swipe…")
                        }
                    }
                    .navigationTitle("Swipe")
                }
                .tabItem {
                    Label("Swipe", systemImage: "rectangle.stack")
                }
                .tag(AppTab.swipe)

                NavigationStack {
                    ExploreView(viewModel: exploreViewModel)
                        .navigationTitle("Explore")
                }
                .tabItem {
                    Label("Explore", systemImage: "magnifyingglass")
                }
                .tag(AppTab.explore)

                NavigationStack {
                    LikedListView(onOpenArtistInExplore: openArtistInExplore)
                        .navigationTitle("Liked")
                }
                .tabItem {
                    Label("Liked", systemImage: "heart.fill")
                }
                .tag(AppTab.liked)

                NavigationStack {
                    PlaylistsView()
                        .navigationTitle("Playlists")
                }
                .tabItem {
                    Label("Playlists", systemImage: "music.note.list")
                }
                .tag(AppTab.playlists)
            }
            .environmentObject(audio)
            .environmentObject(toastManager)
            .safeAreaInset(edge: .bottom) {
                if audio.isPlaying {
                    Color.clear.frame(height: miniPlayerReservedHeight + 8)
                }
            }
            .overlay(alignment: .bottom) {
                ZStack(alignment: .bottom) {
                    if let toast = toastManager.toast {
                        ToastView(toast: toast)
                            .padding(.horizontal, 12)
                            .padding(
                                .bottom,
                                geometry.safeAreaInsets.bottom
                                    + tabBarHeight
                                    + (audio.isPlaying ? miniPlayerReservedHeight + 16 : 8)
                            )
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    if audio.isPlaying {
                        MiniPlayerBar(audio: audio) {
                            if let track = audio.nowPlayingTrack {
                                nowPlayingDetailTrack = track
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, geometry.safeAreaInsets.bottom + tabBarHeight + 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .animation(.easeInOut(duration: 0.22), value: audio.isPlaying)
            .animation(.easeInOut(duration: 0.22), value: toastManager.toast)
            .task {
                exploreViewModel.configureLikesStore(context: modelContext)
                if swipeViewModel == nil {
                    swipeViewModel = SwipeViewModel(
                        service: di.iTunes,
                        likesStore: LikedTracksStore(context: modelContext),
                        audio: audio
                    )
                }
            }
            .sheet(item: $nowPlayingDetailTrack) { track in
                NavigationStack {
                    TrackDetailView(
                        track: track,
                        audio: audio,
                        onOpenArtist: { artistName in
                            nowPlayingDetailTrack = nil
                            openArtistInExplore(artistName)
                        }
                    )
                }
            }
        }
    }

    private func openArtistInExplore(_ artistName: String) {
        let trimmedArtistName = artistName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedArtistName.isEmpty else { return }

        exploreViewModel.suppressAutomaticPresetLoadOnce()
        selectedTab = .explore
        Task { await exploreViewModel.runExternalArtistSearch(trimmedArtistName) }
    }
}

private enum AppTab: Hashable {
    case swipe
    case explore
    case liked
    case playlists
}
