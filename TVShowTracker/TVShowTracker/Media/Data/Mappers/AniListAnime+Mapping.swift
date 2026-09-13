//
//  AniListAnime+Mapping.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

extension AniListAnime {
    var installmentReference: AnimeInstallmentReference {
        AnimeInstallmentReference(
            providerID: id,
            title: title.preferredTitle,
            releaseYear: startDate.year,
            releaseMonth: startDate.month,
            releaseDay: startDate.day,
            episodeCount: episodes,
            status: MediaStatus(anilistStatus: status)
        )
    }

    var isSeasonInstallment: Bool {
        ["TV", "TV_SHORT", "ONA"].contains(format)
    }
}
