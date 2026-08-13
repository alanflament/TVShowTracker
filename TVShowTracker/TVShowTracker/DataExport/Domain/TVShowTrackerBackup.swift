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

struct BackupMedia: Codable, Equatable, Sendable {
    let id: String
    let provider: SearchProvider
    let providerID: Int
    let kind: SearchMediaKind
    let title: String
    let alternateTitle: String?
    let posterURL: URL?
    let releaseYear: Int?
    let totalEpisodeCount: Int?
    let providerStatus: SearchMediaStatus?
    let nextEpisodeNumber: Int?
    let nextEpisodeAirDate: Date?
    let trackingStatus: TrackingStatus
    let addedAt: Date
    let animeInstallments: [AnimeInstallmentReference]

    init(item: LibraryItem) {
        id = item.id
        provider = item.provider
        providerID = item.providerID
        kind = item.kind
        title = item.title
        alternateTitle = item.alternateTitle
        posterURL = item.posterURL
        releaseYear = item.releaseYear
        totalEpisodeCount = item.totalEpisodeCount
        providerStatus = item.status
        nextEpisodeNumber = item.nextEpisodeNumber
        nextEpisodeAirDate = item.nextEpisodeAirDate
        trackingStatus = item.trackingStatus
        addedAt = item.addedAt
        animeInstallments = item.animeInstallments
    }

    var asDomain: LibraryItem {
        LibraryItem(
            provider: provider,
            providerID: providerID,
            kind: kind,
            title: title,
            alternateTitle: alternateTitle,
            posterURL: posterURL,
            releaseYear: releaseYear,
            totalEpisodeCount: totalEpisodeCount,
            status: providerStatus,
            nextEpisodeNumber: nextEpisodeNumber,
            nextEpisodeAirDate: nextEpisodeAirDate,
            animeInstallments: animeInstallments,
            addedAt: addedAt,
            trackingStatus: trackingStatus
        )
    }
}

struct BackupWatchedEpisode: Codable, Equatable, Sendable {
    let id: String
    let watchedAt: Date

    init(episode: WatchedEpisode) {
        id = episode.id
        watchedAt = episode.watchedAt
    }

    var asDomain: WatchedEpisode {
        WatchedEpisode(id: id, watchedAt: watchedAt)
    }
}
