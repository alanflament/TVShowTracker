//
//  EpisodeWatchRepository.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

@MainActor
protocol EpisodeWatchRepository {
    func loadWatchedEpisodes() throws -> [WatchedEpisode]
    func save(_ episode: WatchedEpisode) throws
    func save(_ episodes: [WatchedEpisode]) throws
    func delete(id: String) throws
}
