//
//  SearchCatalog.swift
//  TVShowTracker
//
//  Created by Alan Flament on 10/08/2026.
//

nonisolated struct SearchCatalog: Sendable, Equatable {
    let tvShows: [MediaCandidate]
    let anime: [MediaCandidate]
    let unavailableProviders: Set<MediaProvider>
    let providerErrors: [MediaProvider: String]

    var isEmpty: Bool {
        tvShows.isEmpty && anime.isEmpty
    }
}
