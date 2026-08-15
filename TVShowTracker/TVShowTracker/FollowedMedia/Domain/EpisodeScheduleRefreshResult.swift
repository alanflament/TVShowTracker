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
    let details: ShowDetails?

    init(
        item: LibraryItem,
        seasons: [ShowSeason]?,
        status: SearchMediaStatus?,
        details: ShowDetails? = nil
    ) {
        self.item = item
        self.seasons = seasons
        self.status = status
        self.details = details
    }
}
