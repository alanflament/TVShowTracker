//
//  AppProviderServices.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

@MainActor
struct AppProviderServices {
    let searchCatalogUseCase: any SearchCatalogUseCase
    let showDetailsUseCase: any ShowDetailsUseCase

    init(tmdbAccessToken: String?, language: String) {
        let aniListHTTPClient = RateLimitedHTTPClient(httpClient: URLSessionHTTPClient(), minimumInterval: 2.1)
        let jikanHTTPClient = RateLimitedHTTPClient(httpClient: URLSessionHTTPClient(), minimumInterval: 1.05)
        let animeSearchRepository = FallbackAnimeSearchRepository(
            primaryRepository: AniListAnimeSearchRepository(httpClient: aniListHTTPClient),
            fallbackRepository: JikanAnimeSearchRepository(httpClient: jikanHTTPClient)
        )
        let tvShowSearchRepository: any TVShowSearchRepository

        if let tmdbAccessToken = tmdbAccessToken {
            tvShowSearchRepository = TMDBTVSearchRepository(
                accessToken: tmdbAccessToken,
                language: language
            )
        } else {
            tvShowSearchRepository = UnconfiguredTVShowSearchRepository()
        }

        searchCatalogUseCase = DefaultSearchCatalogUseCase(
            tvShowSearchRepository: tvShowSearchRepository,
            animeSearchRepository: animeSearchRepository
        )

        let tvShowDetailsRepository: any TVShowDetailsRepository
        if let tmdbAccessToken = tmdbAccessToken {
            tvShowDetailsRepository = TMDBShowDetailsRepository(
                accessToken: tmdbAccessToken,
                language: language
            )
        } else {
            tvShowDetailsRepository = UnconfiguredTVShowDetailsRepository()
        }

        showDetailsUseCase = DefaultShowDetailsUseCase(
            tvShowDetailsRepository: tvShowDetailsRepository,
            animeDetailsRepository: AniListAnimeDetailsRepository(httpClient: aniListHTTPClient)
        )
    }
}
