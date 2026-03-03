import SwiftUI
import SwiftData

struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var audio = AudioPlayerService()
    @State private var nowPlayingDetailTrack: Track?
    @State private var swipeViewModel: SwipeViewModel?
    @State private var selectedTab: AppTab = .swipe
    @State private var pendingExploreArtistName: String?
    private let di = AppDIContainer()
    private let miniPlayerReservedHeight: CGFloat = 62
    private let tabBarHeight: CGFloat = 49

    var body: some View {
        GeometryReader { geometry in
            TabView(selection: $selectedTab) {
                NavigationStack {
                    Group {
                        if let swipeViewModel {
                            SwipeView(viewModel: swipeViewModel)
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
                    ExploreView(pendingExploreArtistName: $pendingExploreArtistName)
                        .navigationTitle("Explore")
                }
                .tabItem {
                    Label("Explore", systemImage: "magnifyingglass")
                }
                .tag(AppTab.explore)

                NavigationStack {
                    LikedListView()
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
            .safeAreaInset(edge: .bottom) {
                if audio.isPlaying {
                    Color.clear.frame(height: miniPlayerReservedHeight + 8)
                }
            }
            .overlay(alignment: .bottom) {
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
            .animation(.easeInOut(duration: 0.22), value: audio.isPlaying)
            .task {
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
                    TrackDetailView(track: track, audio: audio)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .openExploreArtist)) { notification in
                guard
                    let artistName = notification.userInfo?["artistName"] as? String,
                    !artistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                else { return }

                pendingExploreArtistName = artistName
                selectedTab = .explore
            }
        }
    }
}

private enum AppTab: Hashable {
    case swipe
    case explore
    case liked
    case playlists
}

extension Notification.Name {
    static let openExploreArtist = Notification.Name("openExploreArtist")
}
