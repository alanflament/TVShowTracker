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
        case loaded([CalendarEpisode], undatedMedia: [CalendarUndatedMedia])
    }

    private let nextEpisodeUseCase: any NextEpisodeUseCase
    private let followedMediaStore: FollowedMediaStore
    private let episodeWatchStore: EpisodeWatchStore
    private let episodeScheduleStore: EpisodeScheduleStore
    private let followedMediaRefreshStore: FollowedMediaRefreshStore

    private(set) var state: State = .idle
    private(set) var refreshMessage: String?

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

    var scheduleCount: Int {
        episodeScheduleStore.schedules.count
    }

    var calendarDataID: String {
        "\(followedMediaIDs.joined(separator: ",")):\(scheduleCount)"
    }

    func refresh() async {
        let items = followedMediaStore.items
        guard !items.isEmpty else {
            state = .loaded([], undatedMedia: [])
            return
        }

        state = .loading
        let result = await nextEpisodeUseCase.findNextEpisode(
            in: items,
            watchedEpisodeIDs: episodeWatchStore.watchedEpisodeIDs,
            now: .now
        )
        state = .loaded(result.episodes, undatedMedia: result.undatedMedia)
    }

    func markEpisodeWatched(_ episode: CalendarEpisode) async {
        episodeWatchStore.markWatched(episode.episode, watchedAt: nil)
        await refresh()
    }

    func refreshFromServer() async {
        await followedMediaRefreshStore.refresh()
        await refresh()

        let refreshedCount = followedMediaRefreshStore.refreshedMediaCount
        let totalCount = followedMediaRefreshStore.totalMediaCount

        if totalCount == 0 {
            refreshMessage = "Your saved schedules are already up to date."
        } else if refreshedCount == totalCount {
            refreshMessage = "Updated \(refreshedCount) \(refreshedCount == 1 ? "schedule" : "schedules")."
        } else {
            refreshMessage = "Updated \(refreshedCount) of \(totalCount) schedules. Saved dates are still shown below."
        }
    }
}
