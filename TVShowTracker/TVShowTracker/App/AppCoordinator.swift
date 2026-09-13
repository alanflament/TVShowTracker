//
//  AppCoordinator.swift
//  TVShowTracker
//
//  Created by Alan Flament on 30/07/2026.
//

import Foundation

@MainActor
final class AppCoordinator {
    let mainCoordinator: MainCoordinator
    let viewModel: AppRootViewModel

    init(
        mainCoordinator: MainCoordinator,
        followedMediaRefreshStore: FollowedMediaRefreshStore
    ) {
        self.mainCoordinator = mainCoordinator
        viewModel = AppRootViewModel(followedMediaRefreshStore: followedMediaRefreshStore)
    }
}
