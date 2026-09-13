//
//  AniListDetailsMapping.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

extension AniListDetailsAnime {
    var asDomain: ShowDetails {
        ShowDetails(
            provider: .aniList,
            providerID: id,
            kind: .anime,
            title: title.preferredTitle,
            alternateTitle: title.alternateTitle,
            overview: description,
            posterURL: coverImage.large ?? coverImage.medium,
            backdropURL: nil,
            releaseYear: startDate.year,
            status: MediaStatus(anilistStatus: status),
            totalEpisodeCount: episodes,
            genres: genres,
            seasonSummaries: episodes.map {
                [SeasonSummary(
                    provider: .aniList,
                    showID: id,
                    number: 1,
                    name: "Episodes",
                    episodeCount: $0,
                    airDate: nil
                )]
            } ?? []
        )
    }
}

extension AniListDetailsRelation {
    var connectsSeasons: Bool {
        ["PREQUEL", "SEQUEL"].contains(relationType) && node.isSeasonInstallment
    }
}

extension AniListDetailsInstallment {
    var isSeasonInstallment: Bool {
        ["TV", "TV_SHORT", "ONA"].contains(format)
    }

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
}
