//
//  TMDBShowDetailsRepository.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

struct TMDBShowDetailsRepository: TVShowDetailsRepository {
    private static let maximumConcurrentSeasonRequests = 3
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
        return try await fetchSeasons(from: details, candidate: candidate)
    }

    func fetchRefreshSnapshot(for candidate: SearchCandidate) async throws -> ShowRefreshSnapshot {
        let details: TMDBShowDetails = try await request(path: "/3/tv/\(candidate.providerID)")
        let domainDetails = details.asDomain
        let seasons: [ShowSeason]?
        if domainDetails.status?.isTerminal == true {
            seasons = nil
        } else {
            seasons = try? await fetchSeasons(from: details, candidate: candidate)
        }
        return ShowRefreshSnapshot(details: domainDetails, seasons: seasons)
    }

    private func fetchSeasons(
        from details: TMDBShowDetails,
        candidate: SearchCandidate
    ) async throws -> [ShowSeason] {
        let summaries = details.seasons.filter { $0.seasonNumber >= 0 }

        return try await withThrowingTaskGroup(of: ShowSeason.self, returning: [ShowSeason].self) { group in
            var pendingSeasons = summaries.makeIterator()

            for _ in 0 ..< min(Self.maximumConcurrentSeasonRequests, summaries.count) {
                guard let season = pendingSeasons.next() else {
                    break
                }
                group.addTask {
                    try await fetchSeason(season.seasonNumber, for: candidate)
                }
            }

            var seasons = [ShowSeason]()
            for try await season in group {
                seasons.append(season)
                if let pendingSeason = pendingSeasons.next() {
                    group.addTask {
                        try await fetchSeason(pendingSeason.seasonNumber, for: candidate)
                    }
                }
            }
            return seasons.sorted { $0.number < $1.number }
        }
    }

    private func fetchSeason(_ number: Int, for candidate: SearchCandidate) async throws -> ShowSeason {
        let seasonDetails: TMDBSeasonDetails = try await request(
            path: "/3/tv/\(candidate.providerID)/season/\(number)"
        )
        return seasonDetails.asDomain(provider: .tmdb, showID: candidate.providerID)
    }

    func fetchEpisodeDetails(
        for candidate: SearchCandidate,
        episode: ShowEpisode
    ) async throws -> EpisodeDetails {
        let details: TMDBEpisode = try await request(
            path: "/3/tv/\(candidate.providerID)/season/\(episode.seasonNumber)/episode/\(episode.number)"
        )
        return details.asEpisodeDetails(
            provider: .tmdb,
            showID: candidate.providerID,
            seasonNumber: episode.seasonNumber
        )
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
