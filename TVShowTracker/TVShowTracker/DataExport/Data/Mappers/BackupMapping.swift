//
//  BackupMapping.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

extension BackupMedia {
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

extension BackupWatchedEpisode {
    init(episode: WatchedEpisode) {
        id = episode.id
        watchedAt = episode.watchedAt
    }

    var asDomain: WatchedEpisode {
        WatchedEpisode(id: id, watchedAt: watchedAt)
    }
}
