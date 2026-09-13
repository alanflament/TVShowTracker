//
//  SearchCatalogUseCase.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

protocol SearchCatalogUseCase: Sendable {
    func search(matching query: String) async -> SearchCatalog
}
