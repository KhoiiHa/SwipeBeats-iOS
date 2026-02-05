import Foundation

protocol ITunesSearching {
    func search(term: String, limit: Int) async throws -> [Track]
    func search(term: String, limit: Int, mode: SearchPreset.Mode) async throws -> [Track]
}

extension ITunesSearching {
    func search(term: String, limit: Int) async throws -> [Track] {
        try await search(term: term, limit: limit, mode: .keyword)
    }
}

final class ITunesSearchService: ITunesSearching {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }

    func search(term: String, limit: Int, mode: SearchPreset.Mode) async throws -> [Track] {
        let url = try makeSearchURL(term: term, limit: limit, mode: mode)
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

    private func makeSearchURL(term: String, limit: Int, mode: SearchPreset.Mode) throws -> URL {
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

        // Narrow the search scope for presets.
        switch mode {
        case .genre:
            components.queryItems?.append(URLQueryItem(name: "attribute", value: "genreIndex"))
        case .artist:
            components.queryItems?.append(URLQueryItem(name: "attribute", value: "artistTerm"))
        case .song:
            components.queryItems?.append(URLQueryItem(name: "attribute", value: "songTerm"))
        case .keyword:
            break
        }

        guard let url = components.url else {
            throw URLError(.badURL)
        }
        return url
    }
}
