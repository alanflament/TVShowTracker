//
//  JikanAnimeSearchRepository.swift
//  TVShowTracker
//
//  Created by Alan Flament on 02/08/2026.
//

import Foundation

struct JikanAnimeSearchRepository: AnimeSearchRepository {
    private let apiClient: JikanAPIClient

    init(httpClient: any HTTPClient = URLSessionHTTPClient()) {
        apiClient = JikanAPIClient(httpClient: httpClient)
    }

    func searchAnime(matching query: String) async throws -> [MediaCandidate] {
        let searchResponse: JikanSearchResponse = try await apiClient.get(
            path: "/v4/anime",
            queryItems: [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "limit", value: "20"),
                URLQueryItem(name: "sfw", value: "true")
            ]
        )

        return searchResponse.data.map(MediaCandidate.init(_:))
    }
}
