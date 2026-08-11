//
//  LibraryCoordinator.swift
//  TVShowTracker
//
//  Created by Alan Flament on 30/07/2026.
//

import SwiftUI

@MainActor @Observable
final class LibraryCoordinator {
    private let followedMediaStore: FollowedMediaStore
    private let detailsCoordinator: DetailsCoordinator

    init(
        followedMediaStore: FollowedMediaStore,
        detailsCoordinator: DetailsCoordinator
    ) {
        self.followedMediaStore = followedMediaStore
        self.detailsCoordinator = detailsCoordinator
    }

    func makeLibraryViewModel() -> LibraryViewModel {
        LibraryViewModel(followedMediaStore: followedMediaStore)
    }

    func makeDetailsView(for candidate: SearchCandidate) -> ShowDetailsView {
        detailsCoordinator.makeDetailsView(for: candidate)
    }
}
