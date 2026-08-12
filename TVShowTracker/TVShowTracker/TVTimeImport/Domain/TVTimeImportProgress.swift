//
//  TVTimeImportProgress.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

struct TVTimeImportProgress: Sendable {
    enum Phase: Sendable {
        case readingExport
        case resolvingShows
        case loadingEpisodeSchedules
    }

    let phase: Phase
    let completedUnitCount: Int
    let totalUnitCount: Int
    let currentTitle: String?
}
