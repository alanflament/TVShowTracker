//
//  BackupMedia.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

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
