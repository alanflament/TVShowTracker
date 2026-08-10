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

    init(searchCatalogUseCase: any SearchCatalogUseCase) {
        self.searchCatalogUseCase = searchCatalogUseCase
    }

    func makeSearchViewModel() -> SearchViewModel {
        SearchViewModel(searchCatalogUseCase: searchCatalogUseCase)
    }
}
