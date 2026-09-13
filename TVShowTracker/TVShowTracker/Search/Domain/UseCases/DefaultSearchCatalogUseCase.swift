//
//  DefaultSearchCatalogUseCase.swift
//  TVShowTracker
//
//  Created by Alan Flament on 30/07/2026.
//

import Foundation

struct DefaultSearchCatalogUseCase: SearchCatalogUseCase {
    private let tvShowRepository: any TVShowSearchRepository
    private let animeRepository: any AnimeSearchRepository

    init(
        tvShowRepository: any TVShowSearchRepository,
        animeRepository: any AnimeSearchRepository
    ) {
        self.tvShowRepository = tvShowRepository
        self.animeRepository = animeRepository
    }

    func search(matching query: String) async -> SearchCatalog {
        async let tvShows = searchTVShows(matching: query)
        async let anime = searchAnime(matching: query)

        let tvShowResult = await tvShows
        let animeResult = await anime

        return SearchCatalog(
            tvShows: tvShowResult.candidates,
            anime: animeResult.candidates,
            unavailableProviders: tvShowResult.unavailableProviders.union(animeResult.unavailableProviders),
            providerErrors: tvShowResult.providerErrors.merging(animeResult.providerErrors) { _, latest in latest }
        )
    }

    private func searchTVShows(matching query: String) async -> SearchProviderResult {
        do {
            return try SearchProviderResult(candidates: await tvShowRepository.searchTVShows(matching: query))
        } catch {
            return SearchProviderResult(
                unavailableProviders: [.tmdb],
                providerErrors: [.tmdb: error.searchFailureMessage]
            )
        }
    }

    private func searchAnime(matching query: String) async -> SearchProviderResult {
        do {
            return try SearchProviderResult(candidates: await animeRepository.searchAnime(matching: query))
        } catch let error as AnimeSearchError {
            return SearchProviderResult(
                unavailableProviders: Set(error.providerErrors.keys),
                providerErrors: error.providerErrors
            )
        } catch {
            return SearchProviderResult(
                unavailableProviders: [.aniList],
                providerErrors: [.aniList: error.searchFailureMessage]
            )
        }
    }
}

private extension Error {
    var searchFailureMessage: String {
        (self as? LocalizedError)?.errorDescription ?? "This source could not be reached."
    }
}
