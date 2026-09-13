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
        let aniListHTTPClient = RateLimitedHTTPClient(client: URLSessionHTTPClient(), minimumInterval: 2.1)
        let jikanHTTPClient = RateLimitedHTTPClient(client: URLSessionHTTPClient(), minimumInterval: 1.05)
        let animeSearchRepository = FallbackAnimeSearchRepository(
            primary: AniListAnimeSearchRepository(httpClient: aniListHTTPClient),
            fallback: JikanAnimeSearchRepository(httpClient: jikanHTTPClient)
        )
        let tvShowRepository: any TVShowSearchRepository

        if let tmdbAccessToken = tmdbAccessToken {
            tvShowRepository = TMDBTVSearchRepository(
                accessToken: tmdbAccessToken,
                language: language
            )
        } else {
            tvShowRepository = UnconfiguredTVShowSearchRepository()
        }

        searchCatalogUseCase = DefaultSearchCatalogUseCase(
            tvShowRepository: tvShowRepository,
            animeRepository: animeSearchRepository
        )

        let detailsTVRepository: any TVShowDetailsRepository
        if let tmdbAccessToken = tmdbAccessToken {
            detailsTVRepository = TMDBShowDetailsRepository(
                accessToken: tmdbAccessToken,
                language: language
            )
        } else {
            detailsTVRepository = UnconfiguredTVShowDetailsRepository()
        }

        showDetailsUseCase = DefaultShowDetailsUseCase(
            tvShowRepository: detailsTVRepository,
            animeRepository: AniListAnimeDetailsRepository(httpClient: aniListHTTPClient)
        )
    }
}
