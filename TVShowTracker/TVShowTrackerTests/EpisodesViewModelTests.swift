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
}

private struct EmptyEpisodesUseCaseStub: ShowDetailsUseCase {
    func fetchDetails(for _: SearchCandidate) async throws -> ShowDetails {
        throw EpisodeDetailsError.notFound
    }

    func fetchEpisodes(for _: SearchCandidate) async throws -> [ShowSeason] {
        []
    }
}
