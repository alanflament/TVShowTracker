//
//  EpisodeDetails.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/08/2026.
//

import Foundation

nonisolated struct EpisodeDetails: Codable, Identifiable, Hashable, Sendable {
    let episode: ShowEpisode
    let voteAverage: Double?
    let fetchedAt: Date

    init(
        episode: ShowEpisode,
        voteAverage: Double? = nil,
        fetchedAt: Date = .now
    ) {
        self.episode = episode
        self.voteAverage = voteAverage
        self.fetchedAt = fetchedAt
    }

    var id: String {
        episode.id
    }
}
