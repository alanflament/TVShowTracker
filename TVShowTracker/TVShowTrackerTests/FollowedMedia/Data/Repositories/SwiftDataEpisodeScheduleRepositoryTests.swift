//
//  SwiftDataEpisodeScheduleRepositoryTests.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import SwiftData
import Testing
@testable import TVShowTracker

@MainActor
struct SwiftDataEpisodeScheduleRepositoryTests {
    @Test func swiftDataEpisodeScheduleRepositoryPersistsSchedules() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: EpisodeScheduleModel.self,
            configurations: configuration
        )
        let repository = SwiftDataEpisodeScheduleRepository(modelContext: container.mainContext)
        let episode = ShowEpisode.tvShow(id: 42, season: 1, number: 3)
        let schedule = EpisodeSchedule(
            itemID: "tmdb:42",
            seasons: [ShowSeason(
                provider: .tmdb,
                showID: 42,
                number: 1,
                name: "Season 1",
                episodes: [episode]
            )]
        )

        try repository.save(schedule)

        let savedSchedule = try repository.loadSchedules().first
        #expect(savedSchedule?.id == schedule.id)
        #expect(savedSchedule?.seasons == schedule.seasons)
    }
}
