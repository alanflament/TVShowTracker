//
//  FallbackAnimeSearchRepository.swift
//  TVShowTracker
//
//  Created by Alan Flament on 02/08/2026.
//

import Foundation

struct FallbackAnimeSearchRepository: AnimeSearchRepository {
    private let primary: any AnimeSearchRepository
    private let fallback: any AnimeSearchRepository

    init(
        primary: any AnimeSearchRepository,
        fallback: any AnimeSearchRepository
    ) {
        self.primary = primary
        self.fallback = fallback
    }

    func searchAnime(matching query: String) async throws -> [SearchCandidate] {
        do {
            return try await primary.searchAnime(matching: query)
        } catch {
            let primaryError = error.searchFailureMessage

            do {
                return try await fallback.searchAnime(matching: query)
            } catch {
                throw FallbackAnimeSearchError(
                    providerErrors: [
                        .aniList: primaryError,
                        .jikan: error.searchFailureMessage,
                    ]
                )
            }
        }
    }
}

struct FallbackAnimeSearchError: LocalizedError, Sendable {
    let providerErrors: [SearchProvider: String]

    var errorDescription: String? {
        "All anime search sources are unavailable."
    }
}

private extension Error {
    var searchFailureMessage: String {
        (self as? LocalizedError)?.errorDescription ?? "This source could not be reached."
    }
}
