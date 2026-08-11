//
//  FollowedMediaRefreshStore.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Observation

@MainActor @Observable
final class FollowedMediaRefreshStore {
    private let refreshUseCase: any EpisodeScheduleRefreshUseCase
    private let followedMediaStore: FollowedMediaStore
    private let episodeScheduleStore: EpisodeScheduleStore

    private(set) var isRefreshing = false
    private(set) var refreshedMediaCount = 0
    private(set) var totalMediaCount = 0

    init(
        refreshUseCase: any EpisodeScheduleRefreshUseCase,
        followedMediaStore: FollowedMediaStore,
        episodeScheduleStore: EpisodeScheduleStore
    ) {
        self.refreshUseCase = refreshUseCase
        self.followedMediaStore = followedMediaStore
        self.episodeScheduleStore = episodeScheduleStore
    }

    func refresh() async {
        guard !isRefreshing else {
            return
        }

        let allItems = followedMediaStore.items
        let items = allItems.filter(\.requiresEpisodeScheduleRefresh)
        totalMediaCount = items.count
        refreshedMediaCount = 0
        isRefreshing = true
        defer { isRefreshing = false }

        episodeScheduleStore.removeSchedules(excluding: Set(allItems.map(\.id)))
        let results = await refreshUseCase.refreshSchedules(for: items)
        for result in results {
            if let status = result.status {
                followedMediaStore.updateStatus(status, for: result.item)
            }
            guard let seasons = result.seasons else {
                continue
            }
            episodeScheduleStore.save(item: result.item, seasons: seasons)
            refreshedMediaCount += 1
        }
    }
}
