//
//  AppRootViewModel.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

@MainActor
final class AppRootViewModel {
    private let followedMediaRefreshStore: FollowedMediaRefreshStore

    init(followedMediaRefreshStore: FollowedMediaRefreshStore) {
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
