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

    @Test func refreshPublishesProgressAndStopsRefreshingWhenComplete() async {
        let items = [makeItem(id: 1), makeItem(id: 2)]
        let libraryStore = FollowedMediaStore(repository: LibraryRepositoryStub(items: items))
        let scheduleStore = EpisodeScheduleStore(repository: ScheduleRepositoryStub())
        let episodeWatchStore = EpisodeWatchStore(
            repository: WatchRepositoryStub(),
            followedMediaStore: libraryStore,
            episodeScheduleStore: scheduleStore
        )
        let progressGate = RefreshProgressGate()
        let refreshStore = FollowedMediaRefreshStore(
            refreshUseCase: ProgressiveScheduleRefreshUseCaseStub(gate: progressGate),
            followedMediaStore: libraryStore,
            episodeWatchStore: episodeWatchStore,
            episodeScheduleStore: scheduleStore
        )

        let refreshTask = Task {
            await refreshStore.refresh()
        }
        for _ in 0 ..< 100 where refreshStore.processedMediaCount == 0 {
            await Task.yield()
        }

        #expect(refreshStore.isRefreshing)
        #expect(refreshStore.processedMediaCount == 1)
        #expect(refreshStore.totalMediaCount == 2)

        await progressGate.release()
        await refreshTask.value

        #expect(!refreshStore.isRefreshing)
        #expect(refreshStore.processedMediaCount == 2)
    }

    @Test func refreshRestoresAnOngoingCompletedMediaToWatching() async {
        let item = makeItem(id: 1, trackingStatus: .completed)
        let libraryStore = FollowedMediaStore(repository: LibraryRepositoryStub(items: [item]))
        let scheduleStore = EpisodeScheduleStore(repository: ScheduleRepositoryStub())
        let episodeWatchStore = EpisodeWatchStore(
            repository: WatchRepositoryStub(),
            followedMediaStore: libraryStore,
            episodeScheduleStore: scheduleStore
        )
        let refreshStore = FollowedMediaRefreshStore(
            refreshUseCase: ScheduleRefreshUseCaseStub(result: EpisodeScheduleRefreshResult(
                item: item,
                seasons: [],
                status: .airing
            )),
            followedMediaStore: libraryStore,
            episodeWatchStore: episodeWatchStore,
            episodeScheduleStore: scheduleStore
        )

        await refreshStore.refresh(force: true)

        #expect(libraryStore.items.first?.trackingStatus == .watching)
    }

    private func makeItem(
        id: Int,
        trackingStatus: TrackingStatus = .watching
    ) -> LibraryItem {
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
        ), trackingStatus: trackingStatus)
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

private actor RefreshProgressGate {
    private var isReleased = false
    private var continuation: CheckedContinuation<Void, Never>?

    func waitForRelease() async {
        guard !isReleased else {
            return
        }

        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func release() {
        isReleased = true
        continuation?.resume()
        continuation = nil
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

    func refreshSchedules(
        for _: [LibraryItem],
        onResult: @escaping @Sendable (EpisodeScheduleRefreshResult) async -> Void
    ) async -> [EpisodeScheduleRefreshResult] {
        await onResult(result)
        return [result]
    }
}

private struct ProgressiveScheduleRefreshUseCaseStub: EpisodeScheduleRefreshUseCase {
    let gate: RefreshProgressGate

    func refreshSchedules(
        for items: [LibraryItem],
        onResult: @escaping @Sendable (EpisodeScheduleRefreshResult) async -> Void
    ) async -> [EpisodeScheduleRefreshResult] {
        var results = [EpisodeScheduleRefreshResult]()

        for (index, item) in items.enumerated() {
            let result = EpisodeScheduleRefreshResult(item: item, seasons: [], status: nil)
            results.append(result)
            await onResult(result)

            if index == 0 {
                await gate.waitForRelease()
            }
        }

        return results
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
    func delete(ids _: [String]) throws {}
}
