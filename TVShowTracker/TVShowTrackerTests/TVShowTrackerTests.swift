//
//  TVShowTrackerTests.swift
//  TVShowTrackerTests
//
//  Created by Alan Flament on 29/07/2026.
//

import Testing
@testable import TVShowTracker

@MainActor
struct TVShowTrackerTests {
    @Test func searchSortsEachProviderSectionAlphabetically() async {
        let useCase = DefaultSearchCatalogUseCase(
            tvShowRepository: TVShowRepositoryStub(candidates: [
                .tvShow(id: 2, title: "The Bear"),
                .tvShow(id: 1, title: "Abbott Elementary"),
            ]),
            animeRepository: AnimeRepositoryStub(candidates: [
                .anime(id: 2, title: "Zom 100"),
                .anime(id: 1, title: "Attack on Titan"),
            ])
        )

        let catalog = await useCase.search(matching: "a")

        #expect(catalog.tvShows.map(\.title) == ["Abbott Elementary", "The Bear"])
        #expect(catalog.anime.map(\.title) == ["Attack on Titan", "Zom 100"])
        #expect(catalog.unavailableProviders.isEmpty)
    }

    @Test func searchReturnsAvailableProviderWhenTheOtherProviderFails() async {
        let useCase = DefaultSearchCatalogUseCase(
            tvShowRepository: FailingTVShowRepository(),
            animeRepository: AnimeRepositoryStub(candidates: [.anime(id: 1, title: "Frieren")])
        )

        let catalog = await useCase.search(matching: "frieren")

        #expect(catalog.tvShows.isEmpty)
        #expect(catalog.anime.map(\.title) == ["Frieren"])
        #expect(catalog.unavailableProviders == [.tmdb])
    }

    @Test func animeFallbackUsesJikanWhenAniListFails() async throws {
        let repository = FallbackAnimeSearchRepository(
            primary: FailingAnimeRepository(),
            fallback: AnimeRepositoryStub(candidates: [.jikanAnime(id: 1, title: "Frieren")])
        )

        let candidates = try await repository.searchAnime(matching: "frieren")

        #expect(candidates.map(\.title) == ["Frieren"])
        #expect(candidates.map(\.provider) == [.jikan])
    }
}

private struct TVShowRepositoryStub: TVShowSearchRepository {
    let candidates: [SearchCandidate]

    func searchTVShows(matching _: String) async throws -> [SearchCandidate] {
        candidates
    }
}

private struct AnimeRepositoryStub: AnimeSearchRepository {
    let candidates: [SearchCandidate]

    func searchAnime(matching _: String) async throws -> [SearchCandidate] {
        candidates
    }
}

private struct FailingTVShowRepository: TVShowSearchRepository {
    func searchTVShows(matching _: String) async throws -> [SearchCandidate] {
        throw TestError.expectedFailure
    }
}

private struct FailingAnimeRepository: AnimeSearchRepository {
    func searchAnime(matching _: String) async throws -> [SearchCandidate] {
        throw TestError.expectedFailure
    }
}

private enum TestError: Error {
    case expectedFailure
}

private extension SearchCandidate {
    static func tvShow(id: Int, title: String) -> SearchCandidate {
        SearchCandidate(
            provider: .tmdb,
            providerID: id,
            kind: .tvShow,
            title: title,
            alternateTitle: nil,
            posterURL: nil,
            releaseYear: nil,
            totalEpisodeCount: nil,
            status: nil,
            nextEpisodeNumber: nil,
            nextEpisodeAirDate: nil
        )
    }

    static func anime(id: Int, title: String) -> SearchCandidate {
        SearchCandidate(
            provider: .aniList,
            providerID: id,
            kind: .anime,
            title: title,
            alternateTitle: nil,
            posterURL: nil,
            releaseYear: nil,
            totalEpisodeCount: nil,
            status: nil,
            nextEpisodeNumber: nil,
            nextEpisodeAirDate: nil
        )
    }

    static func jikanAnime(id: Int, title: String) -> SearchCandidate {
        SearchCandidate(
            provider: .jikan,
            providerID: id,
            kind: .anime,
            title: title,
            alternateTitle: nil,
            posterURL: nil,
            releaseYear: nil,
            totalEpisodeCount: nil,
            status: nil,
            nextEpisodeNumber: nil,
            nextEpisodeAirDate: nil
        )
    }
}
