//
//  TVShowDetailsRepository.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

protocol TVShowDetailsRepository: Sendable {
    func fetchDetails(for candidate: SearchCandidate) async throws -> ShowDetails
    func fetchEpisodes(for candidate: SearchCandidate) async throws -> [ShowSeason]
}
