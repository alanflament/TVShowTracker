//
//  FallbackAnimeDetailsRepository.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

struct FallbackAnimeDetailsRepository: AnimeDetailsRepository {
    private let primary: any AnimeDetailsRepository
    private let fallback: any AnimeDetailsRepository

    init(
        primary: any AnimeDetailsRepository,
        fallback: any AnimeDetailsRepository
    ) {
        self.primary = primary
        self.fallback = fallback
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
        let preferred = candidate.provider == .jikan ? fallback : primary
        let alternative = candidate.provider == .jikan ? primary : fallback
        do {
            return try await operation(preferred)
        } catch {
            try error.rethrowIfCancellation()
            return try await operation(alternative)
        }
    }
}
