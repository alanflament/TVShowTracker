//
//  EpisodeScheduleTests.swift
//  TVShowTrackerTests
//
//  Created by Alan Flament on 12/08/2026.
//

import Testing
@testable import TVShowTracker

struct EpisodeScheduleTests {
    @Test func keepsSeasonZeroSpecialsAfterRegularSeasons() {
        let schedule = EpisodeSchedule(
            itemID: "tmdb:1",
            seasons: [
                ShowSeason(
                    provider: .tmdb,
                    showID: 1,
                    number: 0,
                    name: "Specials",
                    episodes: []
                ),
                ShowSeason(
                    provider: .tmdb,
                    showID: 1,
                    number: 1,
                    name: "Season 1",
                    episodes: []
                ),
                ShowSeason(
                    provider: .tmdb,
                    showID: 1,
                    number: 2,
                    name: "Season 2",
                    episodes: []
                )
            ]
        )

        #expect(schedule.seasons.map(\.number) == [1, 2, 0])
        #expect(schedule.seasons.last?.displayName == "Specials")
    }
}
