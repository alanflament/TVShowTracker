//
//  EpisodeDetailsRepository.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/08/2026.
//

@MainActor
protocol EpisodeDetailsRepository {
    func loadEpisodeDetails() throws -> [EpisodeDetails]
    func save(_ details: EpisodeDetails) throws
}
