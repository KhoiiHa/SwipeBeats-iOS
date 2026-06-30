import XCTest
import SwiftData
@testable import SwipeBeats

@MainActor
final class SwipeBeatsTests: XCTestCase {

    func testExploreFiltersTracksWithoutPreview() async {
        let viewModel = ExploreViewModel(service: MockSearchService(results: [
            makeTrack(id: 1, title: "Playable", previewURL: URL(string: "https://example.com/1.m4a")),
            makeTrack(id: 2, title: "Silent", previewURL: nil)
        ]))

        viewModel.query = "test"
        await viewModel.searchCurrentQuery()

        XCTAssertEqual(viewModel.results.map(\.id), [1])
        XCTAssertEqual(viewModel.state, .content)
    }

    func testExploreSortsTracksAlphabetically() async {
        let viewModel = ExploreViewModel(service: MockSearchService(results: [
            makeTrack(id: 1, title: "Zulu"),
            makeTrack(id: 2, title: "Alpha")
        ]))

        viewModel.query = "test"
        viewModel.sortOption = .trackAZ
        await viewModel.searchCurrentQuery()

        XCTAssertEqual(viewModel.results.map(\.trackName), ["Alpha", "Zulu"])
    }

    func testExploreShowsNetworkErrorState() async {
        let viewModel = ExploreViewModel(service: MockSearchService(error: URLError(.notConnectedToInternet)))

        viewModel.query = "test"
        await viewModel.searchCurrentQuery()

        XCTAssertEqual(viewModel.state, .error("Keine Internetverbindung."))
    }

    func testExploreKeepsErrorStateWhenFiltersChange() async {
        let viewModel = ExploreViewModel(service: MockSearchService(error: URLError(.timedOut)))

        viewModel.query = "test"
        await viewModel.searchCurrentQuery()
        viewModel.onlyWithPreview = false
        viewModel.applyFilters()

        XCTAssertEqual(viewModel.state, .error("Zeitüberschreitung. Bitte erneut versuchen."))
    }

    func testSwipeSkipMovesToNextTrack() async {
        let viewModel = SwipeViewModel(
            service: MockSearchService(results: [
                makeTrack(id: 1, title: "First"),
                makeTrack(id: 2, title: "Second")
            ]),
            audio: AudioPlayerService()
        )

        await viewModel.load(term: "test")
        viewModel.skip()

        XCTAssertEqual(viewModel.currentTrack?.id, 2)
        XCTAssertEqual(viewModel.state, .content)
    }

    func testSwipeSkipStopsActivePlayback() async {
        let audio = AudioPlayerService()
        let viewModel = SwipeViewModel(
            service: MockSearchService(results: [
                makeTrack(id: 1, title: "First")
            ]),
            audio: audio
        )

        await viewModel.load(term: "test")
        audio.play(url: makeTrack(id: 1, title: "First").previewURL!)
        viewModel.skip()

        XCTAssertEqual(audio.state, .stopped)
        XCTAssertNil(audio.nowPlayingTrack)
    }

    func testSwipeSkipLastTrackShowsEmptyState() async {
        let viewModel = SwipeViewModel(
            service: MockSearchService(results: [
                makeTrack(id: 1, title: "Only")
            ]),
            audio: AudioPlayerService()
        )

        await viewModel.load(term: "test")
        viewModel.skip()

        XCTAssertNil(viewModel.currentTrack)
        XCTAssertEqual(viewModel.state, .empty)
    }

    func testAudioQueueTracksNextState() {
        let audio = AudioPlayerService()

        audio.playQueue([
            makeTrack(id: 1, title: "First", previewURL: URL(string: "https://example.com/first.m4a")),
            makeTrack(id: 2, title: "Second", previewURL: URL(string: "https://example.com/second.m4a"))
        ])

        XCTAssertEqual(audio.nowPlayingTrack?.id, 1)
        XCTAssertTrue(audio.hasNextTrack)

        audio.playNext()

        XCTAssertEqual(audio.nowPlayingTrack?.id, 2)
        XCTAssertFalse(audio.hasNextTrack)

        audio.stop()
    }

    func testAudioQueueCanStartAtSelectedTrack() {
        let audio = AudioPlayerService()

        audio.playQueue([
            makeTrack(id: 1, title: "First", previewURL: URL(string: "https://example.com/first.m4a")),
            makeTrack(id: 2, title: "Second", previewURL: URL(string: "https://example.com/second.m4a"))
        ], startAt: 1)

        XCTAssertEqual(audio.nowPlayingTrack?.id, 2)
        XCTAssertFalse(audio.hasNextTrack)

        audio.stop()
    }

    func testLikedTracksStoreSyncsLikedIdsAcrossInstances() async throws {
        let container = try ModelContainer(
            for: LikedTrackEntity.self,
            PlaylistEntity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let firstStore = LikedTracksStore(context: context)
        let secondStore = LikedTracksStore(context: context)

        firstStore.like(makeTrack(id: 42, title: "Synced"))
        await waitForStoreSync {
            secondStore.isLiked(trackId: 42)
        }

        XCTAssertTrue(secondStore.isLiked(trackId: 42))

        secondStore.unlike(trackId: 42)
        await waitForStoreSync {
            firstStore.isLiked(trackId: 42) == false
        }

        XCTAssertFalse(firstStore.isLiked(trackId: 42))
    }
}

private struct MockSearchService: ITunesSearching {
    var results: [Track] = []
    var error: Error?

    func search(term: String, limit: Int, mode: SearchPreset.Mode, genreId: Int?) async throws -> [Track] {
        if let error {
            throw error
        }
        return Array(results.prefix(limit))
    }
}

private func makeTrack(
    id: Int,
    title: String,
    artist: String = "Artist",
    previewURL: URL? = URL(string: "https://example.com/preview.m4a")
) -> Track {
    Track(
        id: id,
        artistName: artist,
        trackName: title,
        artworkURL: nil,
        previewURL: previewURL,
        collectionViewURL: nil,
        primaryGenreName: nil
    )
}

private func waitForStoreSync(_ isSynced: () -> Bool) async {
    for _ in 0..<5 where isSynced() == false {
        await Task.yield()
    }
}
