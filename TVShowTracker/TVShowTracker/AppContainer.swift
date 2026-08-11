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
    private let showDetailsUseCase: any ShowDetailsUseCase

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

        let animeSearchRepository = FallbackAnimeSearchRepository(
            primary: AniListAnimeSearchRepository(),
            fallback: JikanAnimeSearchRepository()
        )

        searchCatalogUseCase = DefaultSearchCatalogUseCase(
            tvShowRepository: tvShowRepository,
            animeRepository: animeSearchRepository
        )

        let language = Locale.current.language.languageCode?.identifier ?? "en-US"
        let detailsTVRepository: any TVShowDetailsRepository
        if let tmdbAccessToken = Self.tmdbAccessToken {
            detailsTVRepository = TMDBShowDetailsRepository(
                accessToken: tmdbAccessToken,
                language: language
            )
        } else {
            detailsTVRepository = UnconfiguredTVShowDetailsRepository()
        }

        showDetailsUseCase = DefaultShowDetailsUseCase(
            tvShowRepository: detailsTVRepository,
            animeRepository: AniListAnimeDetailsRepository()
        )
    }

    func makeAppCoordinator() -> AppCoordinator {
        AppCoordinator(container: self)
    }

    func makeSearchCoordinator() -> SearchCoordinator {
        SearchCoordinator(
            searchCatalogUseCase: searchCatalogUseCase,
            detailsCoordinator: DetailsCoordinator(useCase: showDetailsUseCase)
        )
    }

    private static var tmdbAccessToken: String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "TMDBAccessToken") as? String else {
            return nil
        }

        let token = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return token.isEmpty ? nil : token
    }
}
