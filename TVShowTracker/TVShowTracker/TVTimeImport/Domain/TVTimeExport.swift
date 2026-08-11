//
//  TVTimeExport.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

struct TVTimeExport: Sendable {
    let followedShows: [TVTimeShow]
    let watchedEpisodes: [TVTimeWatchedEpisode]

    var shows: [TVTimeShow] {
        let watchedShows = watchedEpisodes.map { TVTimeShow(title: $0.showTitle) }
        return Array(Set(followedShows + watchedShows)).sorted { $0.title < $1.title }
    }
}
