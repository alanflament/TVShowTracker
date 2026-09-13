//
//  SearchCoordinator.swift
//  TVShowTracker
//
//  Created by Alan Flament on 30/07/2026.
//

import Foundation

@MainActor
final class SearchCoordinator {
    let viewModel: SearchViewModel
    private let detailsCoordinator: DetailsCoordinator

    init(
        searchCatalogUseCase: any SearchCatalogUseCase,
        followedMediaStore: FollowedMediaStore,
        detailsCoordinator: DetailsCoordinator
    ) {
        viewModel = SearchViewModel(
            searchCatalogUseCase: searchCatalogUseCase,
            followedMediaStore: followedMediaStore
        )
        self.detailsCoordinator = detailsCoordinator
    }

    func makeDetailsSheet(for candidate: MediaCandidate) -> DetailsSheetView {
        detailsCoordinator.makeDetailsSheet(for: candidate)
    }

    func search(for query: String) {
        viewModel.requestSearch(for: query)
    }
}
