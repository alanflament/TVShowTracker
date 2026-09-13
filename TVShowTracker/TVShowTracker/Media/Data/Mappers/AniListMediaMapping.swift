//
//  AniListMediaMapping.swift
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

extension AniListRelationEdge {
    var connectsSeasons: Bool {
        ["PREQUEL", "SEQUEL"].contains(relationType) && node.isSeasonInstallment
    }
}

extension AniListTitle {
    var preferredTitle: String {
        userPreferred ?? english ?? romaji ?? native ?? "Untitled"
    }

    var alternateTitle: String? {
        [english, romaji, native]
            .compactMap { $0 }
            .first { $0 != preferredTitle }
    }
}
