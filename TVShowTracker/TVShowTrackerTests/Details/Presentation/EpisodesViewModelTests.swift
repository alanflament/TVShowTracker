//
//  EpisodesViewModelTests.swift
//  TVShowTrackerTests
//
//  Created by Alan Flament on 13/08/2026.
//

import Foundation
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
            libraryRepository: SwiftDataLibraryRepository(modelContext: container.mainContext)
        )
        let episodeScheduleStore = EpisodeScheduleStore(
            episodeScheduleRepository: SwiftDataEpisodeScheduleRepository(modelContext: container.mainContext)
        )
        let viewModel = EpisodesViewModel(
            candidate: MediaCandidate(
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
            showDetailsUseCase: EmptyEpisodesUseCaseStub(),
            followedMediaStore: followedMediaStore,
            episodeScheduleStore: episodeScheduleStore,
            episodeWatchStore: EpisodeWatchStore(
                episodeWatchRepository: SwiftDataEpisodeWatchRepository(modelContext: container.mainContext)
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
            libraryRepository: SwiftDataLibraryRepository(modelContext: container.mainContext)
        )
        let episodeScheduleStore = EpisodeScheduleStore(
            episodeScheduleRepository: SwiftDataEpisodeScheduleRepository(modelContext: container.mainContext)
        )
        let episodeWatchStore = EpisodeWatchStore(
            episodeWatchRepository: SwiftDataEpisodeWatchRepository(modelContext: container.mainContext)
        )
        let viewModel = EpisodesViewModel(
            candidate: candidate,
            showDetailsUseCase: EmptyEpisodesUseCaseStub(),
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

    @Test func watchingAnEpisodeAddsAnUnfollowedMediaAsWatching() async throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: LibraryItemModel.self,
            WatchedEpisodeModel.self,
            EpisodeScheduleModel.self,
            configurations: configuration
        )
        let followedMediaStore = FollowedMediaStore(
            libraryRepository: SwiftDataLibraryRepository(modelContext: container.mainContext)
        )
        let episodeScheduleStore = EpisodeScheduleStore(
            episodeScheduleRepository: SwiftDataEpisodeScheduleRepository(modelContext: container.mainContext)
        )
        let episodeWatchStore = EpisodeWatchStore(
            episodeWatchRepository: SwiftDataEpisodeWatchRepository(modelContext: container.mainContext),
            followedMediaStore: followedMediaStore,
            episodeScheduleStore: episodeScheduleStore
        )
        let watchedEpisode = episode(number: 1)
        let season = ShowSeason(
            provider: .tmdb,
            showID: 42,
            number: 1,
            name: "Season 1",
            episodes: [watchedEpisode, episode(number: 2)]
        )
        let viewModel = EpisodesViewModel(
            candidate: candidate,
            showDetailsUseCase: EpisodesUseCaseStub(seasons: [season]),
            followedMediaStore: followedMediaStore,
            episodeScheduleStore: episodeScheduleStore,
            episodeWatchStore: episodeWatchStore
        )
        let detailsViewModel = ShowDetailsViewModel(
            candidate: candidate,
            showDetailsUseCase: EmptyEpisodesUseCaseStub(),
            followedMediaStore: followedMediaStore
        )

        await viewModel.load()
        #expect(detailsViewModel.trackingStatus == nil)
        viewModel.toggleWatched(watchedEpisode)

        let item = try #require(followedMediaStore.item(id: candidate.id))
        #expect(item.trackingStatus == .watching)
        #expect(episodeWatchStore.isWatched(watchedEpisode))
        #expect(episodeScheduleStore.schedule(for: item)?.seasons == [season])
        #expect(detailsViewModel.trackingStatus == .watching)
    }

    private var candidate: MediaCandidate {
        MediaCandidate(
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
            airDate: .distantPast,
            stillURL: nil,
            runtimeMinutes: nil
        )
    }
}
