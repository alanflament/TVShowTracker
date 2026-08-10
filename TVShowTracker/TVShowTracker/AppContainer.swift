//
//  AppContainer.swift
//  TVShowTracker
//
//  Created by Alan Flament on 30/07/2026.
//

import Foundation

@MainActor
final class AppContainer {
    private let searchCatalogUseCase: any SearchCatalogUseCase

    init() {
        let tvShowRepository: any TVShowSearchRepository

        if let tmdbAccessToken = Self.tmdbAccessToken {
            tvShowRepository = TMDBTVSearchRepository(
                accessToken: tmdbAccessToken,
                language: Locale.current.language.languageCode?.identifier ?? "en-US"
            )
        } else {
            tvShowRepository = UnconfiguredTVShowSearchRepository()
        }

        searchCatalogUseCase = DefaultSearchCatalogUseCase(
            tvShowRepository: tvShowRepository,
            animeRepository: FallbackAnimeSearchRepository(
                primary: AniListAnimeSearchRepository(),
                fallback: JikanAnimeSearchRepository()
            )
        )
    }

    func makeAppCoordinator() -> AppCoordinator {
        AppCoordinator(container: self)
    }

    func makeSearchCoordinator() -> SearchCoordinator {
        SearchCoordinator(searchCatalogUseCase: searchCatalogUseCase)
    }

    private static var tmdbAccessToken: String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "TMDBAccessToken") as? String else {
            return nil
        }

        let token = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return token.isEmpty ? nil : token
    }
}
