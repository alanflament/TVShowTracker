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
}

@MainActor
private extension CalendarViewModelTests {
    func makeViewModel(
        item: LibraryItem,
        nextEpisodeUseCase: any NextEpisodeUseCase
    ) -> CalendarViewModel {
        let followedMediaStore = FollowedMediaStore(repository: CalendarLibraryRepositoryStub(items: [item]))
        let episodeScheduleStore = EpisodeScheduleStore(repository: CalendarScheduleRepositoryStub())
        let episodeWatchStore = EpisodeWatchStore(
            repository: CalendarWatchRepositoryStub(),
            followedMediaStore: followedMediaStore,
            episodeScheduleStore: episodeScheduleStore
        )
        let refreshStore = FollowedMediaRefreshStore(
            refreshUseCase: CalendarRefreshUseCaseStub(),
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
        LibraryItem(candidate: SearchCandidate(
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

@MainActor
private final class GatedNextEpisodeUseCase: NextEpisodeUseCase {
    private var results: [NextEpisodeResult]
    private var shouldSuspend = false
    private var continuation: CheckedContinuation<Void, Never>?
    private(set) var isSuspended = false

    init(results: [NextEpisodeResult]) {
        self.results = results
    }

    func suspendNextRequest() {
        shouldSuspend = true
    }

    func resume() {
        continuation?.resume()
        continuation = nil
    }

    func findNextEpisode(
        in _: [LibraryItem],
        watchedEpisodeIDs _: Set<String>,
        now _: Date
    ) async -> NextEpisodeResult {
        if shouldSuspend {
            shouldSuspend = false
            isSuspended = true
            await withCheckedContinuation { continuation in
                self.continuation = continuation
            }
            isSuspended = false
        }
        return results.removeFirst()
    }
}

@MainActor
private struct CalendarLibraryRepositoryStub: LibraryRepository {
    let items: [LibraryItem]

    func loadItems() throws -> [LibraryItem] {
        items
    }

    func save(_: LibraryItem) throws {}
    func delete(id _: String) throws {}
}

@MainActor
private struct CalendarScheduleRepositoryStub: EpisodeScheduleRepository {
    func loadSchedules() throws -> [EpisodeSchedule] {
        []
    }

    func save(_: EpisodeSchedule) throws {}
    func delete(id _: String) throws {}
}

@MainActor
private struct CalendarWatchRepositoryStub: EpisodeWatchRepository {
    func loadWatchedEpisodes() throws -> [WatchedEpisode] {
        []
    }

    func save(_: WatchedEpisode) throws {}
    func save(_: [WatchedEpisode]) throws {}
    func delete(id _: String) throws {}
    func delete(ids _: [String]) throws {}
}

private struct CalendarRefreshUseCaseStub: EpisodeScheduleRefreshUseCase {
    func refreshSchedules(
        for _: [LibraryItem],
        onResult _: @escaping @Sendable (EpisodeScheduleRefreshResult) async -> Void
    ) async -> [EpisodeScheduleRefreshResult] {
        []
    }
}

private enum CalendarViewModelTestError: Error {
    case expectedLoadedState
}
