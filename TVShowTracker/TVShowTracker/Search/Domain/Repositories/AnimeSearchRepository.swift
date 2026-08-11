//
//  AnimeSearchRepository.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

protocol AnimeSearchRepository: Sendable {
    func searchAnime(matching query: String) async throws -> [SearchCandidate]
}
