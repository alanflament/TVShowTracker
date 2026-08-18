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
    @Test func nextEpisodesAreSortedAlphabeticallyByShowTitle() async {
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

        #expect(result.episodes.map(\.episode.id) == [futureEpisode.id, availableEpisode.id])
        #expect(result.undatedMedia.isEmpty)
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

        #expect(result.episodes.map(\.episode.id) == [nextEpisode.id])
    }

    @Test func availableEpisodeCountIncludesEveryUnwatchedReleasedEpisode() async {
        let firstEpisode = makeEpisode(showID: 1, number: 1, airDate: .distantPast)
        let secondEpisode = makeEpisode(showID: 1, number: 2, airDate: .distantPast)
        let item = makeItem(id: 1, title: "The Bear")
        let store = EpisodeScheduleStore(repository: EpisodeScheduleRepositoryStub(schedules: [
            EpisodeSchedule(itemID: item.id, seasons: [ShowSeason(
                provider: .tmdb,
                showID: 1,
                number: 1,
                name: "Season 1",
                episodes: [firstEpisode, secondEpisode]
            )])
        ]))
        let useCase = DefaultNextEpisodeUseCase(episodeScheduleStore: store)

        let result = await useCase.findNextEpisode(in: [item], watchedEpisodeIDs: [], now: .now)

        #expect(result.episodes.count == 1)
        #expect(result.availableEpisodeCount == 2)
        #expect(result.episodes.first?.additionalAvailableEpisodeCount == 1)
    }

    @Test func upcomingEpisodeDoesNotCountLaterUnreleasedEpisodesAsAvailable() async {
        let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let nextEpisode = makeEpisode(showID: 1, number: 1, airDate: now.addingTimeInterval(3600))
        let laterEpisode = makeEpisode(showID: 1, number: 2, airDate: now.addingTimeInterval(7200))
        let item = makeItem(id: 1, title: "The Bear")
        let store = EpisodeScheduleStore(repository: EpisodeScheduleRepositoryStub(schedules: [
            EpisodeSchedule(itemID: item.id, seasons: [ShowSeason(
                provider: .tmdb,
                showID: 1,
                number: 1,
                name: "Season 1",
                episodes: [nextEpisode, laterEpisode]
            )])
        ]))
        let useCase = DefaultNextEpisodeUseCase(episodeScheduleStore: store)

        let result = await useCase.findNextEpisode(in: [item], watchedEpisodeIDs: [], now: now)

        #expect(result.episodes.first?.episode.id == nextEpisode.id)
        #expect(result.episodes.first?.additionalAvailableEpisodeCount == 0)
    }

    @Test func nextReleasedEpisodeUsesExpectedEpisodeIndexWhenAirDatesAreMissing() async {
        let firstEpisode = makeEpisode(showID: 1, number: 1, airDate: .distantPast)
        let secondEpisode = makeEpisode(showID: 1, number: 2, airDate: nil)
        let tenthEpisode = makeEpisode(showID: 1, number: 10, airDate: nil)
        let item = makeItem(id: 1, title: "The Bear")
        let store = EpisodeScheduleStore(repository: EpisodeScheduleRepositoryStub(schedules: [
            EpisodeSchedule(itemID: item.id, seasons: [ShowSeason(
                provider: .tmdb,
                showID: 1,
                number: 1,
                name: "Season 1",
                episodes: [tenthEpisode, secondEpisode, firstEpisode]
            )])
        ]))
        let useCase = DefaultNextEpisodeUseCase(episodeScheduleStore: store)

        let result = await useCase.findNextEpisode(
            in: [item],
            watchedEpisodeIDs: [firstEpisode.id],
            now: .now
        )

        #expect(result.episodes.map(\.episode.id) == [secondEpisode.id])
    }

    @Test func specialEpisodesDoNotAppearAsTheNextCalendarEpisode() async {
        let specialEpisode = makeEpisode(showID: 1, seasonNumber: 0, number: 1, airDate: .distantPast)
        let regularEpisode = makeEpisode(showID: 1, number: 1, airDate: .distantPast)
        let item = makeItem(id: 1, title: "The Bear")
        let store = EpisodeScheduleStore(repository: EpisodeScheduleRepositoryStub(schedules: [
            EpisodeSchedule(itemID: item.id, seasons: [
                ShowSeason(
                    provider: .tmdb,
                    showID: 1,
                    number: 0,
                    name: "Specials",
                    episodes: [specialEpisode]
                ),
                ShowSeason(
                    provider: .tmdb,
                    showID: 1,
                    number: 1,
                    name: "Season 1",
                    episodes: [regularEpisode]
                )
            ])
        ]))
        let useCase = DefaultNextEpisodeUseCase(episodeScheduleStore: store)

        let result = await useCase.findNextEpisode(
            in: [item],
            watchedEpisodeIDs: [],
            now: .now
        )

        #expect(result.episodes.map(\.episode.id) == [regularEpisode.id])
    }

    @Test func undatedOngoingMediaIsPresentedWithoutARefreshNotice() async {
        let airingItem = makeItem(id: 1, title: "The Bear", status: .airing)
        let finishedItem = makeItem(id: 2, title: "Dark", status: .finished)
        let store = EpisodeScheduleStore(repository: EpisodeScheduleRepositoryStub(schedules: []))
        let useCase = DefaultNextEpisodeUseCase(episodeScheduleStore: store)

        let result = await useCase.findNextEpisode(
            in: [finishedItem, airingItem],
            watchedEpisodeIDs: [],
            now: .now
        )

        #expect(result.episodes.isEmpty)
        #expect(result.undatedMedia.map(\.candidate.id) == [airingItem.id])
    }

    @Test func onlyWatchingMediaAppearsInUpNext() async {
        let watchingItem = makeItem(id: 1, title: "The Bear", trackingStatus: .watching)
        let pausedItem = makeItem(id: 2, title: "Severance", trackingStatus: .paused)
        let watchingEpisode = makeEpisode(showID: 1, number: 1, airDate: .distantPast)
        let pausedEpisode = makeEpisode(showID: 2, number: 1, airDate: .distantPast)
        let store = EpisodeScheduleStore(repository: EpisodeScheduleRepositoryStub(schedules: [
            EpisodeSchedule(itemID: watchingItem.id, seasons: [ShowSeason(
                provider: .tmdb,
                showID: 1,
                number: 1,
                name: "Season 1",
                episodes: [watchingEpisode]
            )]),
            EpisodeSchedule(itemID: pausedItem.id, seasons: [ShowSeason(
                provider: .tmdb,
                showID: 2,
                number: 1,
                name: "Season 1",
                episodes: [pausedEpisode]
            )])
        ]))
        let useCase = DefaultNextEpisodeUseCase(episodeScheduleStore: store)

        let result = await useCase.findNextEpisode(
            in: [watchingItem, pausedItem],
            watchedEpisodeIDs: [],
            now: .now
        )

        #expect(result.episodes.map(\.candidate.id) == [watchingItem.id])
        #expect(result.availableEpisodeCount == 1)
    }

    @Test func detectsWhetherPersistedStateContainsAnUpNextEpisode() {
        let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let watchedEpisode = makeEpisode(showID: 1, number: 1, airDate: now.addingTimeInterval(-3600))
        let nextEpisode = makeEpisode(showID: 1, number: 2, airDate: now.addingTimeInterval(3600))
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

        #expect(useCase.hasNextEpisode(in: [item], watchedEpisodeIDs: [watchedEpisode.id], now: now))
        #expect(!useCase.hasNextEpisode(
            in: [item],
            watchedEpisodeIDs: [watchedEpisode.id, nextEpisode.id],
            now: now
        ))
    }
}

private extension DefaultNextEpisodeUseCaseTests {
    func makeItem(
        id: Int,
        title: String,
        status: SearchMediaStatus? = nil,
        trackingStatus: TrackingStatus = .watching
    ) -> LibraryItem {
        LibraryItem(candidate: SearchCandidate(
            provider: .tmdb,
            providerID: id,
            kind: .tvShow,
            title: title,
            alternateTitle: nil,
            posterURL: nil,
            releaseYear: nil,
            totalEpisodeCount: nil,
            status: status,
            nextEpisodeNumber: nil,
            nextEpisodeAirDate: nil
        ), trackingStatus: trackingStatus)
    }

    func makeEpisode(
        showID: Int,
        seasonNumber: Int = 1,
        number: Int,
        airDate: Date?
    ) -> ShowEpisode {
        ShowEpisode(
            provider: .tmdb,
            showID: showID,
            seasonNumber: seasonNumber,
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
