//
//  LibraryItem.swift
//  TVShowTracker
//
//  Created by Alan Flament on 29/07/2026.
//

import Foundation

struct LibraryItem: Identifiable, Hashable, Sendable {
    let provider: SearchProvider
    let providerID: Int
    let kind: SearchMediaKind
    let title: String
    let alternateTitle: String?
    let posterURL: URL?
    let releaseYear: Int?
    let totalEpisodeCount: Int?
    let status: SearchMediaStatus?
    let nextEpisodeNumber: Int?
    let nextEpisodeAirDate: Date?
    let animeInstallments: [AnimeInstallmentReference]
    let addedAt: Date
    let trackingStatus: TrackingStatus

    init(
        candidate: SearchCandidate,
        addedAt: Date = .now,
        trackingStatus: TrackingStatus = .watching
    ) {
        provider = candidate.provider
        providerID = candidate.providerID
        kind = candidate.kind
        title = candidate.title
        alternateTitle = candidate.alternateTitle
        posterURL = candidate.posterURL
        releaseYear = candidate.releaseYear
        totalEpisodeCount = candidate.totalEpisodeCount
        status = candidate.status
        nextEpisodeNumber = candidate.nextEpisodeNumber
        nextEpisodeAirDate = candidate.nextEpisodeAirDate
        animeInstallments = candidate.animeInstallments
        self.addedAt = addedAt
        self.trackingStatus = trackingStatus
    }

    init(
        provider: SearchProvider,
        providerID: Int,
        kind: SearchMediaKind,
        title: String,
        alternateTitle: String?,
        posterURL: URL?,
        releaseYear: Int?,
        totalEpisodeCount: Int?,
        status: SearchMediaStatus?,
        nextEpisodeNumber: Int?,
        nextEpisodeAirDate: Date?,
        animeInstallments: [AnimeInstallmentReference],
        addedAt: Date,
        trackingStatus: TrackingStatus = .watching
    ) {
        self.provider = provider
        self.providerID = providerID
        self.kind = kind
        self.title = title
        self.alternateTitle = alternateTitle
        self.posterURL = posterURL
        self.releaseYear = releaseYear
        self.totalEpisodeCount = totalEpisodeCount
        self.status = status
        self.nextEpisodeNumber = nextEpisodeNumber
        self.nextEpisodeAirDate = nextEpisodeAirDate
        self.animeInstallments = animeInstallments
        self.addedAt = addedAt
        self.trackingStatus = trackingStatus
    }

    var id: String {
        "\(provider.rawValue):\(providerID)"
    }

    var candidate: SearchCandidate {
        SearchCandidate(
            provider: provider,
            providerID: providerID,
            kind: kind,
            title: title,
            alternateTitle: alternateTitle,
            posterURL: posterURL,
            releaseYear: releaseYear,
            totalEpisodeCount: totalEpisodeCount,
            status: status,
            nextEpisodeNumber: nextEpisodeNumber,
            nextEpisodeAirDate: nextEpisodeAirDate,
            animeInstallments: animeInstallments
        )
    }

    var metadata: String {
        candidate.metadata
    }

    var requiresEpisodeScheduleRefresh: Bool {
        status?.requiresEpisodeScheduleRefresh ?? true
    }

    func contains(_ episode: ShowEpisode) -> Bool {
        guard provider == episode.provider else {
            return false
        }
        return providerID == episode.showID
            || animeInstallments.contains { $0.providerID == episode.showID }
    }

    func updating(status: SearchMediaStatus) -> LibraryItem {
        LibraryItem(
            provider: provider,
            providerID: providerID,
            kind: kind,
            title: title,
            alternateTitle: alternateTitle,
            posterURL: posterURL,
            releaseYear: releaseYear,
            totalEpisodeCount: totalEpisodeCount,
            status: status,
            nextEpisodeNumber: nextEpisodeNumber,
            nextEpisodeAirDate: nextEpisodeAirDate,
            animeInstallments: animeInstallments,
            addedAt: addedAt,
            trackingStatus: trackingStatus
        )
    }

    func updating(with details: ShowDetails) -> LibraryItem {
        LibraryItem(
            provider: provider,
            providerID: providerID,
            kind: kind,
            title: details.title,
            alternateTitle: details.alternateTitle,
            posterURL: details.posterURL ?? posterURL,
            releaseYear: details.releaseYear ?? releaseYear,
            totalEpisodeCount: details.totalEpisodeCount ?? totalEpisodeCount,
            status: details.status ?? status,
            nextEpisodeNumber: nextEpisodeNumber,
            nextEpisodeAirDate: nextEpisodeAirDate,
            animeInstallments: animeInstallments,
            addedAt: addedAt,
            trackingStatus: trackingStatus
        )
    }

    func updating(trackingStatus: TrackingStatus) -> LibraryItem {
        LibraryItem(
            provider: provider,
            providerID: providerID,
            kind: kind,
            title: title,
            alternateTitle: alternateTitle,
            posterURL: posterURL,
            releaseYear: releaseYear,
            totalEpisodeCount: totalEpisodeCount,
            status: status,
            nextEpisodeNumber: nextEpisodeNumber,
            nextEpisodeAirDate: nextEpisodeAirDate,
            animeInstallments: animeInstallments,
            addedAt: addedAt,
            trackingStatus: trackingStatus
        )
    }
}
