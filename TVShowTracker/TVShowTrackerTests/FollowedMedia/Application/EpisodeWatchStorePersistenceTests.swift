//
//  EpisodeWatchStorePersistenceTests.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import SwiftData
import Testing
@testable import TVShowTracker

@MainActor
struct EpisodeWatchStorePersistenceTests {
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
