import Foundation
import SwiftData

@MainActor
final class AppDIContainer {

    let iTunes: ITunesSearching

    // IMPORTANT: avoid `= ITunesSearchService()` default argument (actor-isolation issue)
    init(iTunes: ITunesSearching? = nil) {
        self.iTunes = iTunes ?? ITunesSearchService()
    }
}
