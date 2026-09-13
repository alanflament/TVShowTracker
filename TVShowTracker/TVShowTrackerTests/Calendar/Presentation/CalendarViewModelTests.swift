//
//  CalendarViewModelTests.swift
//  TVShowTrackerTests
//
//  Created by Alan Flament on 16/08/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

@MainActor
struct CalendarViewModelTests {
    @Test func markingWatchedKeepsLoadedContentUntilTheNextEpisodeIsReady() async throws {
        let item = makeItem()
        let firstEpisode = CalendarEpisode(item: item, episode: makeEpisode(number: 1))
        let secondEpisode = CalendarEpisode(item: item, episode: makeEpisode(number: 2))
        let nextEpisodeUseCase = GatedNextEpisodeUseCase(results: [
            NextEpisodeResult(episodes: [firstEpisode], availableEpisodeCount: 2, undatedMedia: []),
            NextEpisodeResult(episodes: [secondEpisode], availableEpisodeCount: 1, undatedMedia: [])
        ])
        let viewModel = makeViewModel(item: item, nextEpisodeUseCase: nextEpisodeUseCase)

        await viewModel.refresh()
        nextEpisodeUseCase.suspendNextRequest()
        let markTask = Task {
            await viewModel.markEpisodeWatched(firstEpisode)
        }
        while !nextEpisodeUseCase.isSuspended {
            await Task.yield()
        }

        #expect(try loadedEpisodes(in: viewModel).map(\.episode.id) == [firstEpisode.episode.id])

        nextEpisodeUseCase.resume()
        await markTask.value

        #expect(try loadedEpisodes(in: viewModel).map(\.episode.id) == [secondEpisode.episode.id])
    }

    @Test func replacedSchedulesAndExternalWatchActionsInvalidateCalendarData() {
        let item = makeItem()
        let library = FollowedMediaStore(libraryRepository: CalendarLibraryRepositoryStub(items: [item]))
        let schedules = EpisodeScheduleStore(episodeScheduleRepository: CalendarScheduleRepositoryStub())
        let watches = EpisodeWatchStore(episodeWatchRepository: CalendarWatchRepositoryStub())
        let viewModel = CalendarViewModel(
            nextEpisodeUseCase: DefaultNextEpisodeUseCase(episodeScheduleReader: schedules),
            followedMediaStore: library,
            episodeWatchStore: watches,
            episodeScheduleStore: schedules,
            followedMediaRefreshStore: FollowedMediaRefreshStore(
                episodeScheduleRefreshUseCase: CalendarRefreshUseCaseStub(),
                followedMediaStore: library, episodeWatchStore: watches, episodeScheduleStore: schedules
            )
        )
        schedules.save(item: item, seasons: [])
        let initial = viewModel.calendarDataID
        schedules.save(item: item, seasons: [ShowSeason(
            provider: .tmdb, showID: 42, number: 1, name: "Season 1", episodes: [makeEpisode(number: 1)]
        )])
        let replacement = viewModel.calendarDataID
        #expect(initial != replacement)
        #expect(initial.schedules.count == replacement.schedules.count)

        watches.markWatched(makeEpisode(number: 1), watchedAt: nil)
        #expect(replacement != viewModel.calendarDataID)
    }

    @Test func olderReloadCannotReplaceNewerContent() async throws {
        let item = makeItem()
        let older = CalendarEpisode(item: item, episode: makeEpisode(number: 1))
        let newer = CalendarEpisode(item: item, episode: makeEpisode(number: 2))
        let useCase = GatedNextEpisodeUseCase(results: [
            NextEpisodeResult(episodes: [older], availableEpisodeCount: 2, undatedMedia: []),
            NextEpisodeResult(episodes: [newer], availableEpisodeCount: 1, undatedMedia: [])
        ])
        let viewModel = makeViewModel(item: item, nextEpisodeUseCase: useCase)
        useCase.suspendNextRequest()
        let first = Task { await viewModel.refresh() }
        while !useCase.isSuspended {
            await Task.yield()
        }
        await viewModel.refresh()
        useCase.resume()
        await first.value
        #expect(try loadedEpisodes(in: viewModel).map(\.episode.id) == [newer.episode.id])
    }
}

@MainActor
private extension CalendarViewModelTests {
    func makeViewModel(
        item: LibraryItem,
        nextEpisodeUseCase: any NextEpisodeUseCase
    ) -> CalendarViewModel {
        let followedMediaStore = FollowedMediaStore(libraryRepository: CalendarLibraryRepositoryStub(items: [item]))
        let episodeScheduleStore = EpisodeScheduleStore(episodeScheduleRepository: CalendarScheduleRepositoryStub())
        let episodeWatchStore = EpisodeWatchStore(
            episodeWatchRepository: CalendarWatchRepositoryStub(),
            followedMediaStore: followedMediaStore,
            episodeScheduleStore: episodeScheduleStore
        )
        let refreshStore = FollowedMediaRefreshStore(
            episodeScheduleRefreshUseCase: CalendarRefreshUseCaseStub(),
            followedMediaStore: followedMediaStore,
            episodeWatchStore: episodeWatchStore,
            episodeScheduleStore: episodeScheduleStore
        )
        return CalendarViewModel(
            nextEpisodeUseCase: nextEpisodeUseCase,
            followedMediaStore: followedMediaStore,
            episodeWatchStore: episodeWatchStore,
            episodeScheduleStore: episodeScheduleStore,
            followedMediaRefreshStore: refreshStore
        )
    }

    func makeItem() -> LibraryItem {
        LibraryItem(candidate: MediaCandidate(
            provider: .tmdb,
            providerID: 42,
            kind: .tvShow,
            title: "A show",
            alternateTitle: nil,
            posterURL: nil,
            releaseYear: nil,
            totalEpisodeCount: 2,
            status: .airing,
            nextEpisodeNumber: nil,
            nextEpisodeAirDate: nil
        ))
    }

    func makeEpisode(number: Int) -> ShowEpisode {
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

    func loadedEpisodes(in viewModel: CalendarViewModel) throws -> [CalendarEpisode] {
        guard case let .loaded(episodes, _, _) = viewModel.state else {
            throw CalendarViewModelTestError.expectedLoadedState
        }
        return episodes
    }
}
