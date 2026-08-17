//
//  SearchCoordinator.swift
//  TVShowTracker
//
//  Created by Alan Flament on 30/07/2026.
//

import SwiftUI

@MainActor @Observable
final class SearchCoordinator {
    private let viewModel: SearchViewModel
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

    func makeSearchView() -> SearchView {
        SearchView(
            viewModel: viewModel,
            detailsCoordinator: detailsCoordinator
        )
    }

    func search(for query: String) {
        viewModel.requestSearch(for: query)
    }
}
