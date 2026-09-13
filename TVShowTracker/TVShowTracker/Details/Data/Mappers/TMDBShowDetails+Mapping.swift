//
//  TMDBShowDetails+Mapping.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

extension TMDBShowDetails {
    var asDomain: ShowDetails {
        ShowDetails(
            provider: .tmdb,
            providerID: id,
            kind: .tvShow,
            title: name,
            alternateTitle: originalName,
            overview: overview,
            posterURL: MediaImageURL.tmdb(path: posterPath, size: "w500"),
            backdropURL: MediaImageURL.tmdb(path: backdropPath, size: "w1280"),
            releaseYear: DateParser.parseYear(firstAirDate),
            status: MediaStatus(tmdbStatus: status),
            totalEpisodeCount: numberOfEpisodes,
            genres: genres.map(\.name),
            seasonSummaries: seasons
                .map { $0.asDomain(provider: .tmdb, showID: id) }
                .sorted(by: seasonOrder)
        )
    }

    private func seasonOrder(_ lhs: SeasonSummary, _ rhs: SeasonSummary) -> Bool {
        let lhsIsSpecial = lhs.number == 0
        let rhsIsSpecial = rhs.number == 0
        if lhsIsSpecial != rhsIsSpecial {
            return !lhsIsSpecial
        }
        return lhs.number < rhs.number
    }
}
