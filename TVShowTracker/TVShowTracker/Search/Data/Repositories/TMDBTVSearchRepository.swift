//
//  TMDBTVSearchRepository.swift
//  TVShowTracker
//
//  Created by Alan Flament on 30/07/2026.
//

import Foundation

struct TMDBTVSearchRepository: TVShowSearchRepository {
    private let apiClient: TMDBAPIClient

    init(
        accessToken: String,
        language: String,
        httpClient: any HTTPClient = URLSessionHTTPClient()
    ) {
        apiClient = TMDBAPIClient(accessToken: accessToken, language: language, httpClient: httpClient)
    }

    func searchTVShows(matching query: String) async throws -> [MediaCandidate] {
        let searchResponse: TMDBTVSearchResponse = try await apiClient.get(
            path: "/3/search/tv",
            queryItems: [
                URLQueryItem(name: "query", value: query),
                URLQueryItem(name: "include_adult", value: "false")
            ]
        )

        return searchResponse.results.map(MediaCandidate.init(_:))
    }
}
