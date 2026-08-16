//
//  AppCoordinator.swift
//  TVShowTracker
//
//  Created by Alan Flament on 30/07/2026.
//

import SwiftUI

@MainActor @Observable
final class AppCoordinator {
    let mainCoordinator: MainCoordinator
    private let followedMediaRefreshStore: FollowedMediaRefreshStore

    init(
        container: AppContainer,
        followedMediaRefreshStore: FollowedMediaRefreshStore,
        initialTab: MainCoordinator.Tab
    ) {
        mainCoordinator = MainCoordinator(container: container, initialTab: initialTab)
        self.followedMediaRefreshStore = followedMediaRefreshStore
    }

    var isRefreshingFollowedMedia: Bool {
        followedMediaRefreshStore.isRefreshing
    }

    var followedMediaRefreshMessage: String {
        let processed = followedMediaRefreshStore.processedMediaCount
        let total = followedMediaRefreshStore.totalMediaCount
        if total == 0 {
            return "Checking your saved shows for new episodes…"
        }
        return "Checking \(processed) of \(total) \(total == 1 ? "show" : "shows") for new episodes…"
    }

    func refreshFollowedMedia() async {
        await followedMediaRefreshStore.refresh()
    }
}
