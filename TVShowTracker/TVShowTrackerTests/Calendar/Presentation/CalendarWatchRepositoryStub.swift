//
//  CalendarWatchRepositoryStub.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

@MainActor
struct CalendarWatchRepositoryStub: EpisodeWatchRepository {
    func loadWatchedEpisodes() throws -> [WatchedEpisode] {
        []
    }

    func save(_: WatchedEpisode) throws {}
    func save(_: [WatchedEpisode]) throws {}
    func delete(id _: String) throws {}
    func delete(ids _: [String]) throws {}
}
