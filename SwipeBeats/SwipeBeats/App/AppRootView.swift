import SwiftUI
import SwiftData

struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var audio = AudioPlayerService()
    @State private var nowPlayingDetailTrack: Track?
    @State private var swipeViewModel: SwipeViewModel?
    private let di = AppDIContainer()
    private let miniPlayerReservedHeight: CGFloat = 68
    private let tabBarHeight: CGFloat = 49

    var body: some View {
        GeometryReader { geometry in
            TabView {
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

                NavigationStack {
                    ExploreView()
                        .navigationTitle("Explore")
                }
                .tabItem {
                    Label("Explore", systemImage: "magnifyingglass")
                }

                NavigationStack {
                    LikedListView()
                        .navigationTitle("Liked")
                }
                .tabItem {
                    Label("Liked", systemImage: "heart.fill")
                }
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
        }
    }
}
