//
//  FollowedMediaRefreshStoreTests.swift
//  TVShowTrackerTests
//
//  Created by Alan Flament on 12/08/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

@MainActor
struct FollowedMediaRefreshStoreTests {
    @Test func refreshPublishesProgressAndStopsRefreshingWhenComplete() async {
        let items = [makeItem(id: 1), makeItem(id: 2)]
        let libraryStore = FollowedMediaStore(libraryRepository: LibraryRepositoryStub(items: items))
        let scheduleStore = EpisodeScheduleStore(episodeScheduleRepository: ScheduleRepositoryStub())
        let episodeWatchStore = EpisodeWatchStore(
            episodeWatchRepository: WatchRepositoryStub(),
            followedMediaStore: libraryStore,
            episodeScheduleStore: scheduleStore
        )
        let progressGate = RefreshProgressGate()
        let refreshStore = FollowedMediaRefreshStore(
            episodeScheduleRefreshUseCase: ProgressiveScheduleRefreshUseCaseStub(gate: progressGate),
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
        let libraryStore = FollowedMediaStore(libraryRepository: LibraryRepositoryStub(items: [item]))
        let scheduleStore = EpisodeScheduleStore(episodeScheduleRepository: ScheduleRepositoryStub())
        let episodeWatchStore = EpisodeWatchStore(
            episodeWatchRepository: WatchRepositoryStub(),
            followedMediaStore: libraryStore,
            episodeScheduleStore: scheduleStore
        )
        let refreshStore = FollowedMediaRefreshStore(
            episodeScheduleRefreshUseCase: ScheduleRefreshUseCaseStub(result: EpisodeScheduleRefreshResult(
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

    @Test func refreshDoesNotRecreateRemovedMedia() async {
        let item = makeItem(id: 1)
        let library = FollowedMediaStore(libraryRepository: LibraryRepositoryStub(items: [item]))
        let schedules = EpisodeScheduleStore(episodeScheduleRepository: ScheduleRepositoryStub())
        let refresh = FollowedMediaRefreshStore(
            episodeScheduleRefreshUseCase: RemovingRefreshUseCase(library: library),
            followedMediaStore: library,
            episodeWatchStore: EpisodeWatchStore(episodeWatchRepository: WatchRepositoryStub()),
            episodeScheduleStore: schedules
        )

        await refresh.refresh(force: true)

        #expect(library.items.isEmpty)
        #expect(schedules.schedules.isEmpty)
        #expect(refresh.processedMediaCount == 1)
    }

    private func makeItem(
        id: Int,
        trackingStatus: TrackingStatus = .watching
    ) -> LibraryItem {
        LibraryItem(candidate: MediaCandidate(
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
