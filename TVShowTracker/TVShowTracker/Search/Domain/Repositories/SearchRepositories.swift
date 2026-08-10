//
//  SearchRepositories.swift
//  TVShowTracker
//
//  Created by Alan Flament on 30/07/2026.
//

protocol TVShowSearchRepository: Sendable {
    func searchTVShows(matching query: String) async throws -> [SearchCandidate]
}

protocol AnimeSearchRepository: Sendable {
    func searchAnime(matching query: String) async throws -> [SearchCandidate]
}

protocol SearchCatalogUseCase: Sendable {
    func search(matching query: String) async -> SearchCatalog
}
