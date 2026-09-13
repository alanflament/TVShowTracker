//
//  BackupWatchedEpisode+Mapping.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

extension BackupWatchedEpisode {
    init(episode: WatchedEpisode) {
        id = episode.id
        watchedAt = episode.watchedAt
    }

    var asDomain: WatchedEpisode {
        WatchedEpisode(id: id, watchedAt: watchedAt)
    }
}
