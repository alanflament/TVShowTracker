//
//  WatchedEpisodeModelMapping.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

extension WatchedEpisodeModel {
    convenience init(episode: WatchedEpisode) {
        self.init(id: episode.id, watchedAt: episode.watchedAt)
    }

    func asDomain() -> WatchedEpisode {
        WatchedEpisode(id: id, watchedAt: watchedAt)
    }
}
