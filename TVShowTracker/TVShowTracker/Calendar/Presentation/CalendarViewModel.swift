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

    var scheduleCount: Int {
        episodeScheduleStore.schedules.count
    }

    var calendarDataID: String {
        let libraryState = followedMediaStore.items
            .map { "\($0.id):\($0.trackingStatus.rawValue)" }
            .joined(separator: ",")
        return "\(libraryState):\(scheduleCount)"
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
        let items = followedMediaStore.items
        guard !items.isEmpty else {
            state = .loaded([], availableEpisodeCount: 0, undatedMedia: [])
            return
        }

        if showsLoadingState {
            state = .loading
        }
        let result = await nextEpisodeUseCase.findNextEpisode(
            in: items,
            watchedEpisodeIDs: episodeWatchStore.watchedEpisodeIDs,
            now: .now
        )
        state = .loaded(
            result.episodes,
            availableEpisodeCount: result.availableEpisodeCount,
            undatedMedia: result.undatedMedia
        )
    }
}
