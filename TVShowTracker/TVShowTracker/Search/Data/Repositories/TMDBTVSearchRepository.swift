//
//  TMDBTVSearchRepository.swift
//  TVShowTracker
//
//  Created by Alan Flament on 30/07/2026.
//

import Foundation

struct TMDBTVSearchRepository: TVShowSearchRepository {
    private let accessToken: String
    private let language: String
    private let httpClient: any HTTPClient

    init(
        accessToken: String,
        language: String,
        httpClient: any HTTPClient = URLSessionHTTPClient()
    ) {
        self.accessToken = accessToken
        self.language = language
        self.httpClient = httpClient
    }

    func searchTVShows(matching query: String) async throws -> [SearchCandidate] {
        var components = URLComponents(string: "https://api.themoviedb.org/3/search/tv")
        components?.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "language", value: language),
            URLQueryItem(name: "include_adult", value: "false")
        ]

        guard let url = components?.url else {
            throw HTTPClientError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await httpClient.data(for: request)
        try response.validateSuccessfulStatusCode()

        let searchResponse = try JSONDecoder().decode(TMDBTVSearchResponse.self, from: data)

        return searchResponse.results.map(SearchCandidate.init(_:))
    }
}
