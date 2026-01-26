import Foundation

protocol ITunesSearching {
    func search(term: String, limit: Int) async throws -> [Track]
}

final class ITunesSearchService: ITunesSearching {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }

    func search(term: String, limit: Int) async throws -> [Track] {
        let url = try makeSearchURL(term: term, limit: limit)
        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoded = try decoder.decode(ITunesSearchResponse.self, from: data)
        return decoded.results.compactMap { $0.toDomain() }
    }

    private func makeSearchURL(term: String, limit: Int) throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "itunes.apple.com"
        components.path = "/search"
        components.queryItems = [
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "media", value: "music"),
            URLQueryItem(name: "entity", value: "song"),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }
        return url
    }
}
