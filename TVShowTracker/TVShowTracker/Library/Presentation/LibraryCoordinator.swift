//
//  LibraryCoordinator.swift
//  TVShowTracker
//
//  Created by Alan Flament on 30/07/2026.
//

import Foundation

@MainActor
final class LibraryCoordinator {
    let viewModel: LibraryViewModel
    private let detailsCoordinator: DetailsCoordinator

    init(
        followedMediaStore: FollowedMediaStore,
        detailsCoordinator: DetailsCoordinator
    ) {
        viewModel = LibraryViewModel(followedMediaStore: followedMediaStore)
        self.detailsCoordinator = detailsCoordinator
    }

    func makeDetailsView(for candidate: MediaCandidate) -> ShowDetailsView {
        detailsCoordinator.makeDetailsView(for: candidate)
    }
}
