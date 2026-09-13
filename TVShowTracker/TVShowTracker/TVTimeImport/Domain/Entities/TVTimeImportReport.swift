//
//  TVTimeImportReport.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

nonisolated struct TVTimeImportReport: Sendable {
    let addedShowCount: Int
    let existingShowCount: Int
    let parsedWatchedEpisodeCount: Int
    let restoredEpisodeCount: Int
    let unresolvedShowTitles: [String]
    let unresolvedEpisodeCount: Int
}
