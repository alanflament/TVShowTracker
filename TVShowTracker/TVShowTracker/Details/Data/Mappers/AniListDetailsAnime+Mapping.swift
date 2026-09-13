//
//  AniListDetailsAnime+Mapping.swift
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
