//
//  CalendarViewModel.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation
import Observation

@MainActor @Observable
final class CalendarViewModel {
    enum State {
        case idle
        case loading
        case loaded(
            [CalendarEpisode],
            availableEpisodeCount: Int,
            undatedMedia: [CalendarUndatedMedia]
        )
    }

    private let nextEpisodeUseCase: any NextEpisodeUseCase
    private let followedMediaStore: FollowedMediaStore
    private let episodeWatchStore: EpisodeWatchStore
    private let episodeScheduleStore: EpisodeScheduleStore
    private let followedMediaRefreshStore: FollowedMediaRefreshStore

    private(set) var state: State = .idle
    private var reloadID = UUID()

    init(
        nextEpisodeUseCase: any NextEpisodeUseCase,
        followedMediaStore: FollowedMediaStore,
        episodeWatchStore: EpisodeWatchStore,
        episodeScheduleStore: EpisodeScheduleStore,
        followedMediaRefreshStore: FollowedMediaRefreshStore
    ) {
        self.nextEpisodeUseCase = nextEpisodeUseCase
        self.followedMediaStore = followedMediaStore
        self.episodeWatchStore = episodeWatchStore
        self.episodeScheduleStore = episodeScheduleStore
        self.followedMediaRefreshStore = followedMediaRefreshStore
    }

    var followedMediaIDs: [String] {
        followedMediaStore.items.map(\.id)
    }

    var watchingMediaIDs: [String] {
        followedMediaStore.items
            .filter { $0.trackingStatus.appearsInUpNext }
            .map(\.id)
    }

    struct DataID: Equatable {
        let items: [LibraryItem]
        let schedules: [String: EpisodeSchedule]
        let watchedEpisodeIDs: Set<String>
    }

    var calendarDataID: DataID {
        DataID(
            items: followedMediaStore.items,
            schedules: episodeScheduleStore.schedules,
            watchedEpisodeIDs: episodeWatchStore.watchedEpisodeIDs
        )
    }

    func refresh() async {
        await reload(showsLoadingState: isInitialLoad)
    }

    func markEpisodeWatched(_ episode: CalendarEpisode) async {
        episodeWatchStore.markWatched(episode.episode, watchedAt: nil)
        await reload(showsLoadingState: false)
    }

    func refreshFromServer() async {
        await followedMediaRefreshStore.refresh(force: true)
        await reload(showsLoadingState: false)
    }
}

private extension CalendarViewModel {
    var isInitialLoad: Bool {
        if case .idle = state {
            true
        } else {
            false
        }
    }

    func reload(showsLoadingState: Bool) async {
        let requestID = UUID()
        reloadID = requestID
        let dataID = calendarDataID
        let items = dataID.items
        guard !items.isEmpty else {
            state = .loaded([], availableEpisodeCount: 0, undatedMedia: [])
            return
        }

        if showsLoadingState {
            state = .loading
        }
        let result = await nextEpisodeUseCase.findNextEpisode(
            in: items,
            watchedEpisodeIDs: dataID.watchedEpisodeIDs,
            now: .now
        )
        guard !Task.isCancelled, reloadID == requestID, calendarDataID == dataID else {
            return
        }
        state = .loaded(
            result.episodes,
            availableEpisodeCount: result.availableEpisodeCount,
            undatedMedia: result.undatedMedia
        )
    }
}
