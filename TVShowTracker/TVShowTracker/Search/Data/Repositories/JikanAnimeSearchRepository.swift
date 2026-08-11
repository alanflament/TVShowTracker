//
//  JikanAnimeSearchRepository.swift
//  TVShowTracker
//
//  Created by Alan Flament on 02/08/2026.
//

import Foundation

struct JikanAnimeSearchRepository: AnimeSearchRepository {
    private let httpClient: any HTTPClient

    init(httpClient: any HTTPClient = URLSessionHTTPClient()) {
        self.httpClient = httpClient
    }

    func searchAnime(matching query: String) async throws -> [SearchCandidate] {
        var components = URLComponents(string: "https://api.jikan.moe/v4/anime")
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: "20"),
            URLQueryItem(name: "sfw", value: "true")
        ]

        guard let url = components?.url else {
            throw HTTPClientError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await httpClient.data(for: request)
        try response.validateSuccessfulStatusCode()

        let searchResponse = try JSONDecoder().decode(JikanSearchResponse.self, from: data)

        return searchResponse.data.map(SearchCandidate.init(_:))
    }
}
