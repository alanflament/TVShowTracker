//
//  FallbackAnimeDetailsRepository.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

struct FallbackAnimeDetailsRepository: AnimeDetailsRepository {
    private let primaryRepository: any AnimeDetailsRepository
    private let fallbackRepository: any AnimeDetailsRepository

    init(
        primaryRepository: any AnimeDetailsRepository,
        fallbackRepository: any AnimeDetailsRepository
    ) {
        self.primaryRepository = primaryRepository
        self.fallbackRepository = fallbackRepository
    }

    func fetchDetails(for candidate: MediaCandidate) async throws -> ShowDetails {
        try await withRepository(for: candidate) { repository in
            try await repository.fetchDetails(for: candidate)
        }
    }

    func fetchEpisodes(for candidate: MediaCandidate) async throws -> [ShowSeason] {
        try await withRepository(for: candidate) { repository in
            try await repository.fetchEpisodes(for: candidate)
        }
    }

    private func withRepository<Result>(
        for candidate: MediaCandidate,
        operation: (any AnimeDetailsRepository) async throws -> Result
    ) async throws -> Result {
        let preferred = candidate.provider == .jikan ? fallbackRepository : primaryRepository
        let alternative = candidate.provider == .jikan ? primaryRepository : fallbackRepository
        do {
            return try await operation(preferred)
        } catch {
            try error.rethrowIfCancellation()
            return try await operation(alternative)
        }
    }
}
