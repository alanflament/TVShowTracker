//
//  FollowedMediaRefreshStore.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation
import Observation

@MainActor @Observable
final class FollowedMediaRefreshStore {
    private let refreshUseCase: any EpisodeScheduleRefreshUseCase
    private let followedMediaStore: FollowedMediaStore
    private let episodeWatchStore: EpisodeWatchStore
    private let episodeScheduleStore: EpisodeScheduleStore

    private(set) var isRefreshing = false
    private(set) var refreshedMediaCount = 0
    private(set) var totalMediaCount = 0

    init(
        refreshUseCase: any EpisodeScheduleRefreshUseCase,
        followedMediaStore: FollowedMediaStore,
        episodeWatchStore: EpisodeWatchStore,
        episodeScheduleStore: EpisodeScheduleStore
    ) {
        self.refreshUseCase = refreshUseCase
        self.followedMediaStore = followedMediaStore
        self.episodeWatchStore = episodeWatchStore
        self.episodeScheduleStore = episodeScheduleStore
    }

    func refresh(force: Bool = false) async {
        guard !isRefreshing else {
            return
        }

        let allItems = followedMediaStore.items
        let refreshDate = Date.now
        let items = allItems.filter { $0.requiresProviderRefresh(at: refreshDate, force: force) }
        totalMediaCount = items.count
        refreshedMediaCount = 0
        isRefreshing = true
        defer { isRefreshing = false }

        episodeScheduleStore.removeSchedules(excluding: Set(allItems.map(\.id)))
        let results = await refreshUseCase.refreshSchedules(for: items)
        for result in results {
            if let details = result.details {
                followedMediaStore.update(with: details, for: result.item.candidate)
            }
            if let status = result.status {
                let item = followedMediaStore.item(id: result.item.id) ?? result.item
                followedMediaStore.updateStatus(status, for: item)
            }
            if let seasons = result.seasons {
                let item = followedMediaStore.item(id: result.item.id) ?? result.item
                episodeScheduleStore.save(item: item, seasons: seasons)
                refreshedMediaCount += 1
            }

            if let item = followedMediaStore.item(id: result.item.id) {
                episodeWatchStore.reconcileTrackingStatus(for: item)
                if result.details != nil,
                   let updatedItem = followedMediaStore.item(id: result.item.id) {
                    followedMediaStore.recordLifecycleCheck(for: updatedItem, at: refreshDate)
                }
            }
        }
    }
}
