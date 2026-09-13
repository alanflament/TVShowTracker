//
//  TVShowSearchRepository.swift
//  TVShowTracker
//
//  Created by Alan Flament on 30/07/2026.
//

protocol TVShowSearchRepository: Sendable {
    func searchTVShows(matching query: String) async throws -> [MediaCandidate]
}
