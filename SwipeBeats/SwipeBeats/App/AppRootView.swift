import SwiftUI
import SwiftData

struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var audio = AudioPlayerService()
    private let di = AppDIContainer()

    var body: some View {
        TabView {
            NavigationStack {
                SwipeView(viewModel: di.makeSwipeViewModel(context: modelContext))
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
            Group {
                if audio.isPlaying {
                    MiniPlayerBar(audio: audio)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 56)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.22), value: audio.isPlaying)
        }
    }
}
