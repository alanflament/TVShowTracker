//
//  TVTimeWatchedEpisode.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

nonisolated struct TVTimeWatchedEpisode: Hashable, Sendable {
    let showTitle: String
    let seasonNumber: Int
    let episodeNumber: Int
    let watchedAt: Date?

    var normalizedShowTitle: String {
        TVTimeShow(title: showTitle).normalizedTitle
    }
}
