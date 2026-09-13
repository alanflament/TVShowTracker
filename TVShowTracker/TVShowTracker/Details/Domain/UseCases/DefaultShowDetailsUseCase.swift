//
//  DefaultShowDetailsUseCase.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

struct DefaultShowDetailsUseCase: ShowDetailsUseCase {
    private let tvShowDetailsRepository: any TVShowDetailsRepository
    private let animeDetailsRepository: any AnimeDetailsRepository

    init(
        tvShowDetailsRepository: any TVShowDetailsRepository,
        animeDetailsRepository: any AnimeDetailsRepository
    ) {
        self.tvShowDetailsRepository = tvShowDetailsRepository
        self.animeDetailsRepository = animeDetailsRepository
    }

    func fetchDetails(for candidate: MediaCandidate) async throws -> ShowDetails {
        switch candidate.kind {
        case .tvShow:
            try await tvShowDetailsRepository.fetchDetails(for: candidate)
        case .anime:
            try await animeDetailsRepository.fetchDetails(for: candidate)
        }
    }

    func fetchEpisodes(for candidate: MediaCandidate) async throws -> [ShowSeason] {
        switch candidate.kind {
        case .tvShow:
            try await tvShowDetailsRepository.fetchEpisodes(for: candidate)
        case .anime:
            try await animeDetailsRepository.fetchEpisodes(for: candidate)
        }
    }

    func fetchRefreshSnapshot(for candidate: MediaCandidate) async throws -> ShowRefreshSnapshot {
        switch candidate.kind {
        case .tvShow:
            try await tvShowDetailsRepository.fetchRefreshSnapshot(for: candidate)
        case .anime:
            try await animeDetailsRepository.fetchRefreshSnapshot(for: candidate)
        }
    }

    func fetchEpisodeDetails(
        for candidate: MediaCandidate,
        episode: ShowEpisode
    ) async throws -> EpisodeDetails {
        switch candidate.kind {
        case .tvShow:
            try await tvShowDetailsRepository.fetchEpisodeDetails(for: candidate, episode: episode)
        case .anime:
            try await animeDetailsRepository.fetchEpisodeDetails(for: candidate, episode: episode)
        }
    }
}
