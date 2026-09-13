//
//  TVShowTrackerBackup.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/08/2026.
//

import Foundation

struct TVShowTrackerBackup: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 1

    let schemaVersion: Int
    let exportedAt: Date
    let media: [BackupMedia]
    let watchedEpisodes: [BackupWatchedEpisode]
}

extension TVShowTrackerBackup {
    init(
        exportedAt: Date,
        media: [BackupMedia],
        watchedEpisodes: [BackupWatchedEpisode]
    ) {
        schemaVersion = Self.currentSchemaVersion
        self.exportedAt = exportedAt
        self.media = media
        self.watchedEpisodes = watchedEpisodes
    }
}
