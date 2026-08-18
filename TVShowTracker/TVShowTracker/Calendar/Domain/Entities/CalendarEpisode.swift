//
//  CalendarEpisode.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

struct CalendarEpisode: Hashable, Sendable {
    let candidate: SearchCandidate
    let showTitle: String
    let posterURL: URL?
    let episode: ShowEpisode
    let additionalAvailableEpisodeCount: Int

    init(
        item: LibraryItem,
        episode: ShowEpisode,
        additionalAvailableEpisodeCount: Int = 0
    ) {
        candidate = item.candidate
        showTitle = item.title
        posterURL = item.posterURL
        self.episode = episode
        self.additionalAvailableEpisodeCount = additionalAvailableEpisodeCount
    }
}
