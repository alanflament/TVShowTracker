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

    init(container: AppContainer, followedMediaRefreshStore: FollowedMediaRefreshStore) {
        mainCoordinator = MainCoordinator(container: container)
        self.followedMediaRefreshStore = followedMediaRefreshStore
    }

    var isRefreshingFollowedMedia: Bool {
        followedMediaRefreshStore.isRefreshing
    }

    var followedMediaRefreshMessage: String {
        let total = followedMediaRefreshStore.totalMediaCount
        if total == 0 {
            return "Refreshing your library…"
        }
        return "Refreshing \(total) followed \(total == 1 ? "show" : "shows")…"
    }

    func refreshFollowedMedia() async {
        await followedMediaRefreshStore.refresh()
    }
}
