//
//  TVShowTrackerTests.swift
//  TVShowTrackerTests
//
//  Created by Alan Flament on 29/07/2026.
//

import Foundation
import SwiftData
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

    @Test func animeDetailsDecodesAniListMediaResponse() async throws {
        let data = Data(#"""
        {
          "data": {
            "Media": {
              "id": 20,
              "title": {
                "userPreferred": "NARUTO",
                "english": "Naruto",
                "romaji": "NARUTO",
                "native": "NARUTO -ナルト-"
              },
              "description": "A ninja story.",
              "coverImage": { "large": null, "medium": null },
              "status": "FINISHED",
              "episodes": 220,
              "startDate": { "year": 2002 },
              "genres": ["Action"]
            }
          }
        }
        """#.utf8)
        let repository = AniListAnimeDetailsRepository(
            httpClient: HTTPClientStub(data: data, statusCode: 200)
        )

        let details = try await repository.fetchDetails(for: .anime(id: 20, title: "Naruto"))

        #expect(details.providerID == 20)
        #expect(details.title == "NARUTO")
        #expect(details.totalEpisodeCount == 220)
    }

    @Test func animeSearchGroupsSequelChainIntoSeasons() async throws {
        let repository = AniListAnimeSearchRepository(
            httpClient: HTTPClientStub(data: .dandadanAniListSearchResponse, statusCode: 200)
        )

        let candidates = try await repository.searchAnime(matching: "Dandadan")

        #expect(candidates.count == 1)
        #expect(candidates.first?.title == "Dandadan")
        #expect(candidates.first?.totalEpisodeCount == 24)
        #expect(candidates.first?.animeInstallments.map(\.providerID) == [171_018, 185_660, 198_966])
    }

    @Test func swiftDataLibraryRepositoryPersistsAndDeletesItems() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: LibraryItemModel.self,
            configurations: configuration
        )
        let repository = SwiftDataLibraryRepository(modelContext: container.mainContext)
        let candidate = SearchCandidate.tvShow(id: 42, title: "The Bear")

        try repository.save(LibraryItem(candidate: candidate))
        let savedItems = try repository.loadItems()

        #expect(savedItems.map(\.id) == [candidate.id])
        #expect(savedItems.first?.candidate == candidate)

        try repository.delete(id: candidate.id)

        #expect(try repository.loadItems().isEmpty)
    }

    @Test func followedMediaStateIsSharedThroughFeatureViewModels() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: LibraryItemModel.self,
            configurations: configuration
        )
        let store = FollowedMediaStore(
            repository: SwiftDataLibraryRepository(modelContext: container.mainContext)
        )
        let searchViewModel = SearchViewModel(
            searchCatalogUseCase: DefaultSearchCatalogUseCase(
                tvShowRepository: TVShowRepositoryStub(),
                animeRepository: AnimeRepositoryStub()
            ),
            followedMediaStore: store
        )
        let libraryViewModel = LibraryViewModel(followedMediaStore: store)
        let candidate = SearchCandidate.tvShow(id: 42, title: "The Bear")

        #expect(!searchViewModel.isFollowed(candidate))

        searchViewModel.toggleFollowed(candidate)

        #expect(searchViewModel.isFollowed(candidate))
        #expect(libraryViewModel.items.map(\.id) == [candidate.id])
    }

    @Test func episodeWatchStorePersistsAndTogglesWatchedState() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: WatchedEpisodeModel.self,
            configurations: configuration
        )
        let repository = SwiftDataEpisodeWatchRepository(modelContext: container.mainContext)
        let store = EpisodeWatchStore(repository: repository)
        let episode = ShowEpisode.tvShow(id: 42, season: 1, number: 3)

        #expect(!store.isWatched(episode))

        store.toggle(episode)

        #expect(store.isWatched(episode))
        #expect(try repository.loadWatchedEpisodes().map(\.id) == [episode.id])

        store.toggle(episode)

        #expect(!store.isWatched(episode))
        #expect(try repository.loadWatchedEpisodes().isEmpty)
    }
}

private extension Data {
    static var dandadanAniListSearchResponse: Data {
        Data(#"""
        {
          "data": {
            "Page": {
              "media": [
                {
                  "id": 171018,
                  "title": { "userPreferred": "Dandadan" },
                  "coverImage": {},
                  "format": "TV",
                  "status": "FINISHED",
                  "episodes": 12,
                  "startDate": { "year": 2024, "month": 10, "day": 4 },
                  "relations": {
                    "edges": [{
                      "relationType": "SEQUEL",
                      "node": {
                        "id": 185660,
                        "title": { "userPreferred": "Dandadan 2nd Season" },
                        "coverImage": {},
                        "format": "TV",
                        "status": "FINISHED",
                        "episodes": 12,
                        "startDate": { "year": 2025, "month": 7, "day": 4 }
                      }
                    }]
                  }
                },
                {
                  "id": 185660,
                  "title": { "userPreferred": "Dandadan 2nd Season" },
                  "coverImage": {},
                  "format": "TV",
                  "status": "FINISHED",
                  "episodes": 12,
                  "startDate": { "year": 2025, "month": 7, "day": 4 },
                  "relations": {
                    "edges": [{
                      "relationType": "SEQUEL",
                      "node": {
                        "id": 198966,
                        "title": { "userPreferred": "Dandadan 3rd Season" },
                        "coverImage": {},
                        "format": "TV",
                        "status": "NOT_YET_RELEASED",
                        "episodes": null,
                        "startDate": {}
                      }
                    }]
                  }
                },
                {
                  "id": 198966,
                  "title": { "userPreferred": "Dandadan 3rd Season" },
                  "coverImage": {},
                  "format": "TV",
                  "status": "NOT_YET_RELEASED",
                  "episodes": null,
                  "startDate": {}
                }
              ]
            }
          }
        }
        """#.utf8)
    }
}

private struct HTTPClientStub: HTTPClient {
    let data: Data
    let statusCode: Int

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        guard let url = request.url,
              let response = HTTPURLResponse(
                  url: url,
                  statusCode: statusCode,
                  httpVersion: nil,
                  headerFields: nil
              )
        else {
            throw TestError.expectedFailure
        }
        return (data, response)
    }
}

private struct TVShowRepositoryStub: TVShowSearchRepository {
    let candidates: [SearchCandidate]

    init(candidates: [SearchCandidate] = []) {
        self.candidates = candidates
    }

    func searchTVShows(matching _: String) async throws -> [SearchCandidate] {
        candidates
    }
}

private struct AnimeRepositoryStub: AnimeSearchRepository {
    let candidates: [SearchCandidate]

    init(candidates: [SearchCandidate] = []) {
        self.candidates = candidates
    }

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

private extension ShowEpisode {
    static func tvShow(id: Int, season: Int, number: Int) -> ShowEpisode {
        ShowEpisode(
            provider: .tmdb,
            showID: id,
            seasonNumber: season,
            number: number,
            title: "Episode \(number)",
            overview: nil,
            airDate: .distantPast,
            stillURL: nil,
            runtimeMinutes: nil
        )
    }
}
