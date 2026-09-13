//
//  LibraryItem.swift
//  TVShowTracker
//
//  Created by Alan Flament on 29/07/2026.
//

import Foundation

nonisolated struct LibraryItem: Identifiable, Hashable, Sendable {
    let provider: MediaProvider
    let providerID: Int
    let kind: MediaKind
    let title: String
    let alternateTitle: String?
    let posterURL: URL?
    let releaseYear: Int?
    let totalEpisodeCount: Int?
    private(set) var status: MediaStatus?
    let nextEpisodeNumber: Int?
    let nextEpisodeAirDate: Date?
    let animeInstallments: [AnimeInstallmentReference]
    let addedAt: Date
    private(set) var trackingStatus: TrackingStatus
    private(set) var lastLifecycleCheckAt: Date?

    init(
        candidate: MediaCandidate,
        addedAt: Date = .now,
        trackingStatus: TrackingStatus = .watching,
        lastLifecycleCheckAt: Date? = nil
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
        self.lastLifecycleCheckAt = lastLifecycleCheckAt
    }

    init(
        provider: MediaProvider,
        providerID: Int,
        kind: MediaKind,
        title: String,
        alternateTitle: String?,
        posterURL: URL?,
        releaseYear: Int?,
        totalEpisodeCount: Int?,
        status: MediaStatus?,
        nextEpisodeNumber: Int?,
        nextEpisodeAirDate: Date?,
        animeInstallments: [AnimeInstallmentReference],
        addedAt: Date,
        trackingStatus: TrackingStatus = .watching,
        lastLifecycleCheckAt: Date? = nil
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
        self.lastLifecycleCheckAt = lastLifecycleCheckAt
    }

    var id: String {
        "\(provider.rawValue):\(providerID)"
    }

    var candidate: MediaCandidate {
        MediaCandidate(
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

    var requiresEpisodeScheduleRefresh: Bool {
        status?.requiresEpisodeScheduleRefresh ?? true
    }

    func requiresProviderRefresh(
        at date: Date,
        force: Bool,
        scheduleRefreshedAt: Date?
    ) -> Bool {
        if force {
            return true
        }

        if status?.isTerminal == true {
            guard trackingStatus == .watching || trackingStatus == .completed else {
                return false
            }
            guard let lastLifecycleCheckAt else {
                return true
            }
            return date.timeIntervalSince(lastLifecycleCheckAt) >= Self.terminalRefreshInterval
        }

        guard trackingStatus.appearsInUpNext else {
            return false
        }

        guard let scheduleRefreshedAt else {
            return true
        }
        return date.timeIntervalSince(scheduleRefreshedAt) >= scheduleRefreshInterval
    }

    func contains(_ episode: ShowEpisode) -> Bool {
        if provider == episode.provider, providerID == episode.showID {
            return true
        }
        return episode.provider == .aniList
            && animeInstallments.contains { $0.providerID == episode.showID }
    }

    func updating(status: MediaStatus) -> LibraryItem {
        var item = self
        item.status = status
        return item
    }

    func updating(with details: ShowDetails) -> LibraryItem {
        LibraryItem(
            candidate: candidate.updating(with: details),
            addedAt: addedAt,
            trackingStatus: trackingStatus,
            lastLifecycleCheckAt: lastLifecycleCheckAt
        )
    }

    func updating(trackingStatus: TrackingStatus) -> LibraryItem {
        var item = self
        item.trackingStatus = trackingStatus
        return item
    }

    func updating(lastLifecycleCheckAt: Date) -> LibraryItem {
        var item = self
        item.lastLifecycleCheckAt = lastLifecycleCheckAt
        return item
    }
}

private extension LibraryItem {
    nonisolated static let terminalRefreshInterval: TimeInterval = 30 * 24 * 60 * 60
    nonisolated static let dailyRefreshInterval: TimeInterval = 24 * 60 * 60
    nonisolated static let hiatusRefreshInterval: TimeInterval = 7 * 24 * 60 * 60

    nonisolated var scheduleRefreshInterval: TimeInterval {
        status == .hiatus ? Self.hiatusRefreshInterval : Self.dailyRefreshInterval
    }
}
