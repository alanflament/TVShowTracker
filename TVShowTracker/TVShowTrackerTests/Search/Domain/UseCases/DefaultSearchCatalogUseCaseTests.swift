//
//  DefaultSearchCatalogUseCaseTests.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

@MainActor
struct DefaultSearchCatalogUseCaseTests {
    @Test func searchPreservesEachProviderRelevanceOrder() async {
        let useCase = DefaultSearchCatalogUseCase(
            tvShowSearchRepository: TVShowRepositoryStub(candidates: [
                .tvShow(id: 2, title: "The Bear"),
                .tvShow(id: 1, title: "Abbott Elementary")
            ]),
            animeSearchRepository: AnimeRepositoryStub(candidates: [
                .anime(id: 2, title: "Zom 100"),
                .anime(id: 1, title: "Attack on Titan")
            ])
        )

        let catalog = await useCase.search(matching: "a")

        #expect(catalog.tvShows.map(\.title) == ["The Bear", "Abbott Elementary"])
        #expect(catalog.anime.map(\.title) == ["Zom 100", "Attack on Titan"])
        #expect(catalog.unavailableProviders.isEmpty)
    }

    @Test func searchReturnsAvailableProviderWhenTheOtherProviderFails() async {
        let useCase = DefaultSearchCatalogUseCase(
            tvShowSearchRepository: FailingTVShowRepository(),
            animeSearchRepository: AnimeRepositoryStub(candidates: [.anime(id: 1, title: "Frieren")])
        )

        let catalog = await useCase.search(matching: "frieren")

        #expect(catalog.tvShows.isEmpty)
        #expect(catalog.anime.map(\.title) == ["Frieren"])
        #expect(catalog.unavailableProviders == [.tmdb])
    }
}
