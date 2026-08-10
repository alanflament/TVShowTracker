//
//  SearchCatalog.swift
//  TVShowTracker
//
//  Created by Alan Flament on 10/08/2026.
//

struct SearchCatalog: Sendable, Equatable {
    let tvShows: [SearchCandidate]
    let anime: [SearchCandidate]
    let unavailableProviders: Set<SearchProvider>
    let providerErrors: [SearchProvider: String]

    var isEmpty: Bool {
        tvShows.isEmpty && anime.isEmpty
    }
}
