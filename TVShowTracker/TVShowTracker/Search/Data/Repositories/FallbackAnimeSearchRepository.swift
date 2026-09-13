//
//  FallbackAnimeSearchRepository.swift
//  TVShowTracker
//
//  Created by Alan Flament on 02/08/2026.
//

import Foundation

struct FallbackAnimeSearchRepository: AnimeSearchRepository {
    private let primaryRepository: any AnimeSearchRepository
    private let fallbackRepository: any AnimeSearchRepository

    init(
        primaryRepository: any AnimeSearchRepository,
        fallbackRepository: any AnimeSearchRepository
    ) {
        self.primaryRepository = primaryRepository
        self.fallbackRepository = fallbackRepository
    }

    func searchAnime(matching query: String) async throws -> [MediaCandidate] {
        do {
            return try await primaryRepository.searchAnime(matching: query)
        } catch {
            try error.rethrowIfCancellation()
            let primaryError = error.searchFailureMessage

            do {
                return try await fallbackRepository.searchAnime(matching: query)
            } catch {
                try error.rethrowIfCancellation()
                throw AnimeSearchError(
                    providerErrors: [
                        .aniList: primaryError,
                        .jikan: error.searchFailureMessage
                    ]
                )
            }
        }
    }
}
