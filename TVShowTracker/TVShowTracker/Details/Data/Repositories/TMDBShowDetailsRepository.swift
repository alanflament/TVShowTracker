//
//  TMDBShowDetailsRepository.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

struct TMDBShowDetailsRepository: TVShowDetailsRepository {
    private static let maximumConcurrentSeasonRequests = 3
    private let apiClient: TMDBAPIClient

    init(
        accessToken: String,
        language: String,
        httpClient: any HTTPClient = URLSessionHTTPClient()
    ) {
        apiClient = TMDBAPIClient(accessToken: accessToken, language: language, httpClient: httpClient)
    }

    func fetchDetails(for candidate: MediaCandidate) async throws -> ShowDetails {
        let details: TMDBShowDetails = try await apiClient.get(path: "/3/tv/\(candidate.providerID)")
        return details.asDomain
    }

    func fetchEpisodes(for candidate: MediaCandidate) async throws -> [ShowSeason] {
        let details: TMDBShowDetails = try await apiClient.get(path: "/3/tv/\(candidate.providerID)")
        return try await fetchSeasons(from: details, candidate: candidate)
    }

    func fetchRefreshSnapshot(for candidate: MediaCandidate) async throws -> ShowRefreshSnapshot {
        let details: TMDBShowDetails = try await apiClient.get(path: "/3/tv/\(candidate.providerID)")
        let domainDetails = details.asDomain
        let seasons: [ShowSeason]?
        if domainDetails.status?.isTerminal == true {
            seasons = nil
        } else {
            do {
                seasons = try await fetchSeasons(from: details, candidate: candidate)
            } catch {
                try error.rethrowIfCancellation()
                seasons = nil
            }
        }
        return ShowRefreshSnapshot(details: domainDetails, seasons: seasons)
    }

    private func fetchSeasons(
        from details: TMDBShowDetails,
        candidate: MediaCandidate
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

    private func fetchSeason(_ number: Int, for candidate: MediaCandidate) async throws -> ShowSeason {
        let seasonDetails: TMDBSeasonDetails = try await apiClient.get(
            path: "/3/tv/\(candidate.providerID)/season/\(number)"
        )
        return seasonDetails.asDomain(provider: .tmdb, showID: candidate.providerID)
    }

    func fetchEpisodeDetails(
        for candidate: MediaCandidate,
        episode: ShowEpisode
    ) async throws -> EpisodeDetails {
        let details: TMDBEpisode = try await apiClient.get(
            path: "/3/tv/\(candidate.providerID)/season/\(episode.seasonNumber)/episode/\(episode.number)"
        )
        return details.asEpisodeDetails(
            provider: .tmdb,
            showID: candidate.providerID,
            seasonNumber: episode.seasonNumber
        )
    }
}
