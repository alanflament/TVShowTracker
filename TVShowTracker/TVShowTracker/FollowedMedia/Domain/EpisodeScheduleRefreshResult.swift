//
//  EpisodeScheduleRefreshResult.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

struct EpisodeScheduleRefreshResult: Sendable {
    let item: LibraryItem
    let seasons: [ShowSeason]?
    let status: SearchMediaStatus?
}
