import XCTest
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
}

private struct MockSearchService: ITunesSearching {
    let results: [Track]

    func search(term: String, limit: Int, mode: SearchPreset.Mode, genreId: Int?) async throws -> [Track] {
        Array(results.prefix(limit))
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
