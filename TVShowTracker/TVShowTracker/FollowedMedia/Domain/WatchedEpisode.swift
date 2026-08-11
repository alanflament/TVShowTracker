//
//  WatchedEpisode.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

struct WatchedEpisode: Identifiable, Hashable, Sendable {
    let id: String
    let watchedAt: Date

    init(id: String, watchedAt: Date) {
        self.id = id
        self.watchedAt = watchedAt
    }

    init(episode: ShowEpisode, watchedAt: Date = .now) {
        id = episode.id
        self.watchedAt = watchedAt
    }
}
