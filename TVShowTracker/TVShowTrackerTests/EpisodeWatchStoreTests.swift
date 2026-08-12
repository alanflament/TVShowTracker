//
//  EpisodeWatchStoreTests.swift
//  TVShowTrackerTests
//
//  Created by Alan Flament on 12/08/2026.
//

import SwiftData
import Testing
@testable import TVShowTracker

@MainActor
struct EpisodeWatchStoreTests {
    @Test func marksEpisodesInBatchWithoutDuplicatingThem() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: WatchedEpisodeModel.self,
            configurations: configuration
        )
        let repository = SwiftDataEpisodeWatchRepository(modelContext: container.mainContext)
        let store = EpisodeWatchStore(repository: repository)
        let episodes = [
            makeEpisode(number: 1),
            makeEpisode(number: 2)
        ]

        store.markWatched(episodes)
        store.markWatched(episodes)

        #expect(episodes.allSatisfy(store.isWatched))
        #expect(try repository.loadWatchedEpisodes().map(\WatchedEpisode.id).sorted() == episodes.map(\.id).sorted())
    }

    private func makeEpisode(number: Int) -> ShowEpisode {
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
