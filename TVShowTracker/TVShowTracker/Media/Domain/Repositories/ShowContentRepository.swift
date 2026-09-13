//
//  ShowContentRepository.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

protocol ShowContentRepository: Sendable {
    func fetchDetails(for candidate: MediaCandidate) async throws -> ShowDetails
    func fetchEpisodes(for candidate: MediaCandidate) async throws -> [ShowSeason]
    func fetchRefreshSnapshot(for candidate: MediaCandidate) async throws -> ShowRefreshSnapshot
    func fetchEpisodeDetails(
        for candidate: MediaCandidate,
        episode: ShowEpisode
    ) async throws -> EpisodeDetails
}

extension ShowContentRepository {
    func fetchRefreshSnapshot(for candidate: MediaCandidate) async throws -> ShowRefreshSnapshot {
        let details = try await fetchDetails(for: candidate)
        let seasons: [ShowSeason]?
        if details.status?.isTerminal == true {
            seasons = nil
        } else {
            do {
                seasons = try await fetchEpisodes(for: candidate.updating(with: details))
            } catch {
                try error.rethrowIfCancellation()
                seasons = nil
            }
        }
        return ShowRefreshSnapshot(details: details, seasons: seasons)
    }

    func fetchEpisodeDetails(
        for candidate: MediaCandidate,
        episode: ShowEpisode
    ) async throws -> EpisodeDetails {
        let seasons = try await fetchEpisodes(for: candidate)
        guard let refreshedEpisode = seasons
            .first(where: { $0.number == episode.seasonNumber })?
            .episodes
            .first(where: { $0.number == episode.number }) else {
            throw EpisodeDetailsError.notFound
        }
        return EpisodeDetails(episode: refreshedEpisode)
    }
}
