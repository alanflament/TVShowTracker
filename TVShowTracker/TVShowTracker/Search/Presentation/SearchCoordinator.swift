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
    private let detailsCoordinator: DetailsCoordinator

    init(
        searchCatalogUseCase: any SearchCatalogUseCase,
        detailsCoordinator: DetailsCoordinator
    ) {
        self.searchCatalogUseCase = searchCatalogUseCase
        self.detailsCoordinator = detailsCoordinator
    }

    func makeSearchView() -> SearchView {
        SearchView(
            viewModel: SearchViewModel(searchCatalogUseCase: searchCatalogUseCase),
            detailsCoordinator: detailsCoordinator
        )
    }
}
