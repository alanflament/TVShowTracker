//
//  EpisodeScheduleRefreshResult.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

nonisolated struct EpisodeScheduleRefreshResult: Sendable {
    let item: LibraryItem
    let seasons: [ShowSeason]?
    let status: MediaStatus?
    let details: ShowDetails?

    init(
        item: LibraryItem,
        seasons: [ShowSeason]?,
        status: MediaStatus?,
        details: ShowDetails? = nil
    ) {
        self.item = item
        self.seasons = seasons
        self.status = status
        self.details = details
    }
}
