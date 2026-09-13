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
    private let episodeScheduleRefreshUseCase: any EpisodeScheduleRefreshUseCase
    private let followedMediaStore: FollowedMediaStore
    private let episodeWatchStore: EpisodeWatchStore
    private let episodeScheduleStore: EpisodeScheduleStore

    private(set) var isRefreshing = false
    private(set) var processedMediaCount = 0
    private(set) var totalMediaCount = 0

    init(
        episodeScheduleRefreshUseCase: any EpisodeScheduleRefreshUseCase,
        followedMediaStore: FollowedMediaStore,
        episodeWatchStore: EpisodeWatchStore,
        episodeScheduleStore: EpisodeScheduleStore
    ) {
        self.episodeScheduleRefreshUseCase = episodeScheduleRefreshUseCase
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
        let items = allItems.filter {
            $0.requiresProviderRefresh(
                at: refreshDate,
                force: force,
                scheduleRefreshedAt: episodeScheduleStore.schedule(for: $0)?.refreshedAt
            )
        }
        totalMediaCount = items.count
        processedMediaCount = 0
        episodeScheduleStore.removeSchedules(excluding: Set(allItems.map(\.id)))

        guard !items.isEmpty else {
            return
        }

        isRefreshing = true
        defer { isRefreshing = false }

        _ = await episodeScheduleRefreshUseCase.refreshSchedules(for: items) { [weak self] result in
            guard let self else {
                return
            }

            await apply(result, refreshDate: refreshDate)
        }
    }

    private func apply(_ result: EpisodeScheduleRefreshResult, refreshDate: Date) {
        defer { processedMediaCount += 1 }
        guard !Task.isCancelled, followedMediaStore.item(id: result.item.id) != nil else {
            return
        }
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
