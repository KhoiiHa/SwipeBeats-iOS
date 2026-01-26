import SwiftUI
import SwiftData

struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
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
    }
}
