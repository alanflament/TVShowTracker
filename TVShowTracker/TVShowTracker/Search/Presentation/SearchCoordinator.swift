//
//  SearchCoordinator.swift
//  TVShowTracker
//
//  Created by Alan Flament on 30/07/2026.
//

import SwiftUI

@MainActor @Observable
final class SearchCoordinator {
    private let searchCatalogUseCase: any SearchCatalogUseCase
    private let followedMediaStore: FollowedMediaStore
    private let detailsCoordinator: DetailsCoordinator

    init(
        searchCatalogUseCase: any SearchCatalogUseCase,
        followedMediaStore: FollowedMediaStore,
        detailsCoordinator: DetailsCoordinator
    ) {
        self.searchCatalogUseCase = searchCatalogUseCase
        self.followedMediaStore = followedMediaStore
        self.detailsCoordinator = detailsCoordinator
    }

    func makeSearchView() -> SearchView {
        SearchView(
            viewModel: SearchViewModel(
                searchCatalogUseCase: searchCatalogUseCase,
                followedMediaStore: followedMediaStore
            ),
            detailsCoordinator: detailsCoordinator
        )
    }
}
