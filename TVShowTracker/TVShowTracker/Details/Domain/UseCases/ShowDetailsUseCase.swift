//
//  ShowDetailsUseCase.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

protocol ShowDetailsUseCase: Sendable {
    func fetchDetails(for candidate: SearchCandidate) async throws -> ShowDetails
    func fetchEpisodes(for candidate: SearchCandidate) async throws -> [ShowSeason]
    func fetchRefreshSnapshot(for candidate: SearchCandidate) async throws -> ShowRefreshSnapshot
    func fetchEpisodeDetails(
        for candidate: SearchCandidate,
        episode: ShowEpisode
    ) async throws -> EpisodeDetails
}

extension ShowDetailsUseCase {
    func fetchRefreshSnapshot(for candidate: SearchCandidate) async throws -> ShowRefreshSnapshot {
        let details = try await fetchDetails(for: candidate)
        let seasons: [ShowSeason]?
        if details.status?.isTerminal == true {
            seasons = nil
        } else {
            seasons = try? await fetchEpisodes(for: candidate.updating(with: details))
        }
        return ShowRefreshSnapshot(details: details, seasons: seasons)
    }

    func fetchEpisodeDetails(
        for candidate: SearchCandidate,
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
