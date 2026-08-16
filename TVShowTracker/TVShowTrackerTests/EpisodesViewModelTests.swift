//
//  EpisodesViewModelTests.swift
//  TVShowTrackerTests
//
//  Created by Codex on 13/08/2026.
//
//  Created by Alan Flament on 13/08/2026.
//

import SwiftData
import Testing
@testable import TVShowTracker

@MainActor
struct EpisodesViewModelTests {
    @Test func anEmptySeasonIsNotComplete() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: LibraryItemModel.self,
            WatchedEpisodeModel.self,
            EpisodeScheduleModel.self,
            configurations: configuration
        )
        let followedMediaStore = FollowedMediaStore(
            repository: SwiftDataLibraryRepository(modelContext: container.mainContext)
        )
        let episodeScheduleStore = EpisodeScheduleStore(
            repository: SwiftDataEpisodeScheduleRepository(modelContext: container.mainContext)
        )
        let viewModel = EpisodesViewModel(
            candidate: SearchCandidate(
                provider: .tmdb,
                providerID: 42,
                kind: .tvShow,
                title: "A show",
                alternateTitle: nil,
                posterURL: nil,
                releaseYear: nil,
                totalEpisodeCount: nil,
                status: .upcoming,
                nextEpisodeNumber: nil,
                nextEpisodeAirDate: nil
            ),
            useCase: EmptyEpisodesUseCaseStub(),
            followedMediaStore: followedMediaStore,
            episodeScheduleStore: episodeScheduleStore,
            episodeWatchStore: EpisodeWatchStore(
                repository: SwiftDataEpisodeWatchRepository(modelContext: container.mainContext)
            )
        )

        #expect(!viewModel.areAllWatched(in: []))
    }

    @Test func seasonWatchActionTogglesEveryEpisode() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: LibraryItemModel.self,
            WatchedEpisodeModel.self,
            EpisodeScheduleModel.self,
            configurations: configuration
        )
        let followedMediaStore = FollowedMediaStore(
            repository: SwiftDataLibraryRepository(modelContext: container.mainContext)
        )
        let episodeScheduleStore = EpisodeScheduleStore(
            repository: SwiftDataEpisodeScheduleRepository(modelContext: container.mainContext)
        )
        let episodeWatchStore = EpisodeWatchStore(
            repository: SwiftDataEpisodeWatchRepository(modelContext: container.mainContext)
        )
        let viewModel = EpisodesViewModel(
            candidate: candidate,
            useCase: EmptyEpisodesUseCaseStub(),
            followedMediaStore: followedMediaStore,
            episodeScheduleStore: episodeScheduleStore,
            episodeWatchStore: episodeWatchStore
        )
        let episodes = [episode(number: 1), episode(number: 2)]
        let season = ShowSeason(
            provider: .tmdb,
            showID: 42,
            number: 1,
            name: "Season 1",
            episodes: episodes
        )

        viewModel.toggleSeasonWatched(season)
        #expect(episodes.allSatisfy(viewModel.isWatched))

        viewModel.toggleSeasonWatched(season)
        #expect(episodes.allSatisfy { !viewModel.isWatched($0) })
    }

    private var candidate: SearchCandidate {
        SearchCandidate(
            provider: .tmdb,
            providerID: 42,
            kind: .tvShow,
            title: "A show",
            alternateTitle: nil,
            posterURL: nil,
            releaseYear: nil,
            totalEpisodeCount: nil,
            status: .finished,
            nextEpisodeNumber: nil,
            nextEpisodeAirDate: nil
        )
    }

    private func episode(number: Int) -> ShowEpisode {
        ShowEpisode(
            provider: .tmdb,
            showID: 42,
            seasonNumber: 1,
            number: number,
            title: "Episode \(number)",
            overview: nil,
            airDate: nil,
            stillURL: nil,
            runtimeMinutes: nil
        )
    }
}

private struct EmptyEpisodesUseCaseStub: ShowDetailsUseCase {
    func fetchDetails(for _: SearchCandidate) async throws -> ShowDetails {
        throw EpisodeDetailsError.notFound
    }

    func fetchEpisodes(for _: SearchCandidate) async throws -> [ShowSeason] {
        []
    }
}
