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

struct BackupMedia: Codable, Equatable, Sendable {
    let id: String
    let provider: MediaProvider
    let providerID: Int
    let kind: MediaKind
    let title: String
    let alternateTitle: String?
    let posterURL: URL?
    let releaseYear: Int?
    let totalEpisodeCount: Int?
    let providerStatus: MediaStatus?
    let nextEpisodeNumber: Int?
    let nextEpisodeAirDate: Date?
    let trackingStatus: TrackingStatus
    let addedAt: Date
    let animeInstallments: [AnimeInstallmentReference]
}

struct BackupWatchedEpisode: Codable, Equatable, Sendable {
    let id: String
    let watchedAt: Date
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
