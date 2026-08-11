//
//  CalendarEpisode.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

struct CalendarEpisode: Hashable, Sendable {
    let showTitle: String
    let posterURL: URL?
    let episode: ShowEpisode

    init(item: LibraryItem, episode: ShowEpisode) {
        showTitle = item.title
        posterURL = item.posterURL
        self.episode = episode
    }
}
