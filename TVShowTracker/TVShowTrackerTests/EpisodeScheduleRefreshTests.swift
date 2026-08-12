//
//  EpisodeScheduleRefreshTests.swift
//  TVShowTrackerTests
//
//  Created by Alan Flament on 12/08/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

@MainActor
struct EpisodeScheduleRefreshTests {
    @Test func refreshLimitsTheNumberOfConcurrentProviderRequests() async {
        let probe = RefreshConcurrencyProbe()
        let useCase = DefaultEpisodeScheduleRefreshUseCase(
            showDetailsUseCase: ConcurrentDetailsUseCase(probe: probe)
        )
        let items = (1 ... 10).map { makeItem(id: $0) }

        let results = await useCase.refreshSchedules(for: items)
        let peakConcurrentRequests = await probe.peakConcurrentRequests()

        #expect(results.count == items.count)
        #expect(peakConcurrentRequests <= 4)
    }

    @Test func calendarReportsTheOutcomeOfAManualScheduleRefresh() async {
        let item = makeItem(id: 1)
        let libraryStore = FollowedMediaStore(repository: LibraryRepositoryStub(items: [item]))
        let scheduleStore = EpisodeScheduleStore(repository: ScheduleRepositoryStub())
        let refreshStore = FollowedMediaRefreshStore(
            refreshUseCase: ScheduleRefreshUseCaseStub(result: EpisodeScheduleRefreshResult(
                item: item,
                seasons: [],
                status: nil
            )),
            followedMediaStore: libraryStore,
            episodeScheduleStore: scheduleStore
        )
        let viewModel = CalendarViewModel(
            nextEpisodeUseCase: DefaultNextEpisodeUseCase(episodeScheduleStore: scheduleStore),
            followedMediaStore: libraryStore,
            episodeWatchStore: EpisodeWatchStore(repository: WatchRepositoryStub()),
            episodeScheduleStore: scheduleStore,
            followedMediaRefreshStore: refreshStore
        )

        await viewModel.refreshFromServer()

        #expect(viewModel.refreshMessage == "Updated 1 schedule.")
    }

    private func makeItem(id: Int) -> LibraryItem {
        LibraryItem(candidate: SearchCandidate(
            provider: .tmdb,
            providerID: id,
            kind: .tvShow,
            title: "Show \(id)",
            alternateTitle: nil,
            posterURL: nil,
            releaseYear: nil,
            totalEpisodeCount: nil,
            status: .airing,
            nextEpisodeNumber: nil,
            nextEpisodeAirDate: nil
        ))
    }
}

private actor RefreshConcurrencyProbe {
    private var activeRequestCount = 0
    private var maximumRequestCount = 0

    func beginRequest() {
        activeRequestCount += 1
        maximumRequestCount = max(maximumRequestCount, activeRequestCount)
    }

    func finishRequest() {
        activeRequestCount -= 1
    }

    func peakConcurrentRequests() -> Int {
        maximumRequestCount
    }
}

private struct ConcurrentDetailsUseCase: ShowDetailsUseCase {
    let probe: RefreshConcurrencyProbe

    func fetchDetails(for candidate: SearchCandidate) async throws -> ShowDetails {
        ShowDetails(
            provider: candidate.provider,
            providerID: candidate.providerID,
            kind: candidate.kind,
            title: candidate.title,
            alternateTitle: nil,
            overview: nil,
            posterURL: nil,
            backdropURL: nil,
            releaseYear: nil,
            status: .airing,
            totalEpisodeCount: nil,
            genres: [],
            seasonSummaries: []
        )
    }

    func fetchEpisodes(for _: SearchCandidate) async throws -> [ShowSeason] {
        await probe.beginRequest()
        try? await Task.sleep(nanoseconds: 20_000_000)
        await probe.finishRequest()
        return []
    }
}

private struct ScheduleRefreshUseCaseStub: EpisodeScheduleRefreshUseCase {
    let result: EpisodeScheduleRefreshResult

    func refreshSchedules(for _: [LibraryItem]) async -> [EpisodeScheduleRefreshResult] {
        [result]
    }
}

@MainActor
private struct LibraryRepositoryStub: LibraryRepository {
    let items: [LibraryItem]

    func loadItems() throws -> [LibraryItem] {
        items
    }

    func save(_: LibraryItem) throws {}
    func delete(id _: String) throws {}
}

@MainActor
private struct ScheduleRepositoryStub: EpisodeScheduleRepository {
    func loadSchedules() throws -> [EpisodeSchedule] {
        []
    }

    func save(_: EpisodeSchedule) throws {}
    func delete(id _: String) throws {}
}

@MainActor
private struct WatchRepositoryStub: EpisodeWatchRepository {
    func loadWatchedEpisodes() throws -> [WatchedEpisode] {
        []
    }

    func save(_: WatchedEpisode) throws {}
    func save(_: [WatchedEpisode]) throws {}
    func delete(id _: String) throws {}
}
