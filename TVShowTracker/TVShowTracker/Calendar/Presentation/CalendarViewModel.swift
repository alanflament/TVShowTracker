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
        case loaded([CalendarEpisode], missingScheduleCount: Int)
        case failed(String)
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

    var scheduleCount: Int {
        episodeScheduleStore.schedules.count
    }

    var calendarDataID: String {
        "\(followedMediaIDs.joined(separator: ",")):\(scheduleCount)"
    }

    func refresh() async {
        let items = followedMediaStore.items
        guard !items.isEmpty else {
            state = .loaded([], missingScheduleCount: 0)
            return
        }

        state = .loading
        let result = await nextEpisodeUseCase.findNextEpisode(
            in: items,
            watchedEpisodeIDs: episodeWatchStore.watchedEpisodeIDs,
            now: .now
        )
        state = .loaded(result.episodes, missingScheduleCount: result.missingScheduleCount)
    }

    func markEpisodeWatched(_ episode: CalendarEpisode) async {
        episodeWatchStore.markWatched(episode.episode, watchedAt: nil)
        await refresh()
    }

    func refreshFromServer() async {
        await followedMediaRefreshStore.refresh()
    }
}
