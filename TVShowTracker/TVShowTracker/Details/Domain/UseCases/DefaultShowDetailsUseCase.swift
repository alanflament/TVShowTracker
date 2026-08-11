//
//  DefaultShowDetailsUseCase.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

struct DefaultShowDetailsUseCase: ShowDetailsUseCase {
    private let tvShowRepository: any TVShowDetailsRepository
    private let animeRepository: any AnimeDetailsRepository

    init(
        tvShowRepository: any TVShowDetailsRepository,
        animeRepository: any AnimeDetailsRepository
    ) {
        self.tvShowRepository = tvShowRepository
        self.animeRepository = animeRepository
    }

    func fetchDetails(for candidate: SearchCandidate) async throws -> ShowDetails {
        switch candidate.kind {
        case .tvShow:
            try await tvShowRepository.fetchDetails(for: candidate)
        case .anime:
            try await animeRepository.fetchDetails(for: candidate)
        }
    }

    func fetchEpisodes(for candidate: SearchCandidate) async throws -> [ShowSeason] {
        switch candidate.kind {
        case .tvShow:
            try await tvShowRepository.fetchEpisodes(for: candidate)
        case .anime:
            try await animeRepository.fetchEpisodes(for: candidate)
        }
    }
}
