//
//  TVShowDetailsRepository.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

protocol TVShowDetailsRepository: Sendable {
    func fetchDetails(for candidate: SearchCandidate) async throws -> ShowDetails
    func fetchEpisodes(for candidate: SearchCandidate) async throws -> [ShowSeason]
    func fetchEpisodeDetails(
        for candidate: SearchCandidate,
        episode: ShowEpisode
    ) async throws -> EpisodeDetails
}

extension TVShowDetailsRepository {
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
