//
//  RefreshFixture.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Observation
import SwiftData
import Testing
@testable import TVShowTracker

@MainActor
struct RefreshFixture {
    let modelContainer: ModelContainer
    let store: FollowedMediaRefreshStore
    let gate = RefreshGate()

    init(itemCount: Int) throws {
        modelContainer = try ModelContainer(
            for: LibraryItemModel.self, WatchedEpisodeModel.self, EpisodeScheduleModel.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let library = FollowedMediaStore(
            libraryRepository: SwiftDataLibraryRepository(modelContext: modelContainer.mainContext)
        )
        for index in 0 ..< itemCount {
            library.addIfMissing(.tvShow(id: index + 1, title: "Show \(index + 1)"), trackingStatus: .watching)
        }
        let schedules = EpisodeScheduleStore(
            episodeScheduleRepository: SwiftDataEpisodeScheduleRepository(modelContext: modelContainer.mainContext)
        )
        let watched = EpisodeWatchStore(
            episodeWatchRepository: SwiftDataEpisodeWatchRepository(modelContext: modelContainer.mainContext),
            followedMediaStore: library,
            episodeScheduleStore: schedules
        )
        store = FollowedMediaRefreshStore(
            episodeScheduleRefreshUseCase: PausingRefreshUseCase(gate: gate),
            followedMediaStore: library,
            episodeWatchStore: watched,
            episodeScheduleStore: schedules
        )
    }
}
