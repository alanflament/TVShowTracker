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

    func fetchDetails(for candidate: SearchCandidate) async throws -> ShowDetails {
        if candidate.provider == .jikan {
            do {
                return try await fallback.fetchDetails(for: candidate)
            } catch {
                return try await primary.fetchDetails(for: candidate)
            }
        }

        do {
            return try await primary.fetchDetails(for: candidate)
        } catch {
            return try await fallback.fetchDetails(for: candidate)
        }
    }

    func fetchEpisodes(for candidate: SearchCandidate) async throws -> [ShowSeason] {
        if candidate.provider == .jikan {
            do {
                return try await fallback.fetchEpisodes(for: candidate)
            } catch {
                return try await primary.fetchEpisodes(for: candidate)
            }
        }

        do {
            return try await primary.fetchEpisodes(for: candidate)
        } catch {
            return try await fallback.fetchEpisodes(for: candidate)
        }
    }
}
