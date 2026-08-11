//
//  DefaultNextEpisodeUseCaseTests.swift
//  TVShowTrackerTests
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

@MainActor
struct DefaultNextEpisodeUseCaseTests {
    @Test func releasedUnwatchedEpisodeIsPreferredOverFutureEpisode() async {
        let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let availableEpisode = makeEpisode(showID: 1, number: 2, airDate: now.addingTimeInterval(-3600))
        let futureEpisode = makeEpisode(showID: 2, number: 4, airDate: now.addingTimeInterval(86400))
        let firstItem = makeItem(id: 1, title: "The Bear")
        let secondItem = makeItem(id: 2, title: "Frieren")
        let store = EpisodeScheduleStore(repository: EpisodeScheduleRepositoryStub(schedules: [
            EpisodeSchedule(itemID: firstItem.id, seasons: [ShowSeason(
                provider: .tmdb,
                showID: 1,
                number: 1,
                name: "Season 1",
                episodes: [availableEpisode]
            )]),
            EpisodeSchedule(itemID: secondItem.id, seasons: [ShowSeason(
                provider: .tmdb,
                showID: 2,
                number: 1,
                name: "Season 1",
                episodes: [futureEpisode]
            )])
        ]))
        let useCase = DefaultNextEpisodeUseCase(episodeScheduleStore: store)

        let result = await useCase.findNextEpisode(
            in: [firstItem, secondItem],
            watchedEpisodeIDs: [],
            now: now
        )

        #expect(result.episode?.episode.id == availableEpisode.id)
        #expect(result.missingScheduleCount == 0)
    }

    @Test func watchedEpisodeIsSkippedForTheNextAvailableEpisode() async {
        let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let watchedEpisode = makeEpisode(showID: 1, number: 1, airDate: now.addingTimeInterval(-7200))
        let nextEpisode = makeEpisode(showID: 1, number: 2, airDate: now.addingTimeInterval(-3600))
        let item = makeItem(id: 1, title: "The Bear")
        let store = EpisodeScheduleStore(repository: EpisodeScheduleRepositoryStub(schedules: [
            EpisodeSchedule(itemID: item.id, seasons: [ShowSeason(
                provider: .tmdb,
                showID: 1,
                number: 1,
                name: "Season 1",
                episodes: [watchedEpisode, nextEpisode]
            )])
        ]))
        let useCase = DefaultNextEpisodeUseCase(episodeScheduleStore: store)

        let result = await useCase.findNextEpisode(
            in: [item],
            watchedEpisodeIDs: [watchedEpisode.id],
            now: now
        )

        #expect(result.episode?.episode.id == nextEpisode.id)
    }
}

private extension DefaultNextEpisodeUseCaseTests {
    func makeItem(id: Int, title: String) -> LibraryItem {
        LibraryItem(candidate: SearchCandidate(
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
        ))
    }

    func makeEpisode(showID: Int, number: Int, airDate: Date) -> ShowEpisode {
        ShowEpisode(
            provider: .tmdb,
            showID: showID,
            seasonNumber: 1,
            number: number,
            title: "Episode \(number)",
            overview: nil,
            airDate: airDate,
            stillURL: nil,
            runtimeMinutes: nil
        )
    }
}

private struct EpisodeScheduleRepositoryStub: EpisodeScheduleRepository {
    let schedules: [EpisodeSchedule]

    func loadSchedules() throws -> [EpisodeSchedule] {
        schedules
    }

    func save(_: EpisodeSchedule) throws {}

    func delete(id _: String) throws {}
}
