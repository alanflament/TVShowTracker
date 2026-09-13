//
//  AppRootView.swift
//  TVShowTracker
//
//  Created by Alan Flament on 30/07/2026.
//

import SwiftUI

struct AppRootView: View {
    let coordinator: AppCoordinator

    var body: some View {
        MainCoordinatorView(
            coordinator: coordinator.mainCoordinator
        )
        .safeAreaInset(edge: .top, spacing: 0) {
            if coordinator.isRefreshingFollowedMedia {
                HStack(spacing: 8) {
                    ProgressView()
                    Text(coordinator.followedMediaRefreshMessage)
                        .font(.footnote.weight(.medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(.thinMaterial)
            }
        }
        .task {
            await coordinator.refreshFollowedMedia()
        }
    }
}
