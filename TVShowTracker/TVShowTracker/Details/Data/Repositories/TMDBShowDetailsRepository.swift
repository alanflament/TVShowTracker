//
//  TMDBShowDetailsRepository.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

struct TMDBShowDetailsRepository: TVShowDetailsRepository {
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

    func fetchDetails(for candidate: SearchCandidate) async throws -> ShowDetails {
        let details: TMDBShowDetails = try await request(path: "/3/tv/\(candidate.providerID)")
        return details.asDomain
    }

    func fetchEpisodes(for candidate: SearchCandidate) async throws -> [ShowSeason] {
        let details: TMDBShowDetails = try await request(path: "/3/tv/\(candidate.providerID)")

        return try await withThrowingTaskGroup(of: ShowSeason.self, returning: [ShowSeason].self) { group in
            for season in details.seasons where season.seasonNumber >= 0 {
                group.addTask {
                    let seasonDetails: TMDBSeasonDetails = try await request(
                        path: "/3/tv/\(candidate.providerID)/season/\(season.seasonNumber)"
                    )
                    return seasonDetails.asDomain(
                        provider: .tmdb,
                        showID: candidate.providerID
                    )
                }
            }

            var seasons = [ShowSeason]()
            for try await season in group {
                seasons.append(season)
            }
            return seasons.sorted { $0.number < $1.number }
        }
    }
}

private extension TMDBShowDetailsRepository {
    func request<Response: Decodable>(path: String) async throws -> Response {
        var components = URLComponents(string: "https://api.themoviedb.org")
        components?.path = path
        components?.queryItems = [URLQueryItem(name: "language", value: language)]

        guard let url = components?.url else {
            throw HTTPClientError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await httpClient.data(for: request)
        try response.validateSuccessfulStatusCode()
        return try JSONDecoder().decode(Response.self, from: data)
    }
}
