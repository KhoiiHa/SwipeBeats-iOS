import Foundation

protocol ITunesSearching {
    func search(term: String, limit: Int) async throws -> [Track]
    func search(term: String, limit: Int, mode: SearchPreset.Mode) async throws -> [Track]
    func search(term: String, limit: Int, mode: SearchPreset.Mode, genreId: Int?) async throws -> [Track]
}

extension ITunesSearching {
    func search(term: String, limit: Int) async throws -> [Track] {
        try await search(term: term, limit: limit, mode: .keyword)
    }

    func search(term: String, limit: Int, mode: SearchPreset.Mode) async throws -> [Track] {
        try await search(term: term, limit: limit, mode: mode, genreId: nil)
    }
}

final class ITunesSearchService: ITunesSearching {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }

    func search(term: String, limit: Int, mode: SearchPreset.Mode, genreId: Int?) async throws -> [Track] {
        let url = try makeSearchURL(term: term, limit: limit, mode: mode, genreId: genreId)
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoded = try decoder.decode(ITunesSearchResponse.self, from: data)
        let results = decoded.results.compactMap { $0.toDomain() }

        if mode == .genre, genreId != nil, results.isEmpty {
            let fallbackURL = try makeSearchURL(term: term, limit: limit, mode: .keyword, genreId: nil)
            var fallbackRequest = URLRequest(url: fallbackURL)
            fallbackRequest.timeoutInterval = 15
            let (fallbackData, fallbackResponse) = try await session.data(for: fallbackRequest)

            guard let fallbackHTTP = fallbackResponse as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            guard (200...299).contains(fallbackHTTP.statusCode) else {
                throw URLError(.badServerResponse)
            }

            let fallbackDecoded = try decoder.decode(ITunesSearchResponse.self, from: fallbackData)
            return fallbackDecoded.results.compactMap { $0.toDomain() }
        }

        return results
    }

    private func makeSearchURL(term: String, limit: Int, mode: SearchPreset.Mode, genreId: Int?) throws -> URL {
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
            if let genreId {
                components.queryItems?.removeAll { $0.name == "term" }
                components.queryItems?.append(URLQueryItem(name: "term", value: String(genreId)))
                components.queryItems?.append(URLQueryItem(name: "attribute", value: "genreIndex"))
            } else {
                // default term already set
            }
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
