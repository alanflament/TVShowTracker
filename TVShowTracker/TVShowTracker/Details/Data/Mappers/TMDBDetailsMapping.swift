//
//  TMDBDetailsMapping.swift
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
            posterURL: tmdbImageURL(path: posterPath, size: "w500"),
            backdropURL: tmdbImageURL(path: backdropPath, size: "w1280"),
            releaseYear: DateParser.parseYear(firstAirDate),
            status: MediaStatus(tmdbStatus: status),
            totalEpisodeCount: numberOfEpisodes,
            genres: genres.map(\.name),
            seasonSummaries: seasons
                .map { $0.asDomain(provider: .tmdb, showID: id) }
                .sorted(by: seasonOrder)
        )
    }
}

extension TMDBSeasonSummary {
    func asDomain(provider: MediaProvider, showID: Int) -> SeasonSummary {
        SeasonSummary(
            provider: provider,
            showID: showID,
            number: seasonNumber,
            name: name,
            episodeCount: episodeCount,
            airDate: DateParser.parseISO8601(airDate)
        )
    }
}

extension TMDBSeasonDetails {
    nonisolated func asDomain(provider: MediaProvider, showID: Int) -> ShowSeason {
        ShowSeason(
            provider: provider,
            showID: showID,
            number: seasonNumber,
            name: name,
            episodes: episodes.compactMap {
                // TMDB can publish placeholder episode records before a schedule is confirmed.
                guard $0.hasConfirmedAirDate else {
                    return nil
                }
                return $0.asDomain(provider: provider, showID: showID, seasonNumber: seasonNumber)
            }
        )
    }
}

extension TMDBEpisode {
    nonisolated var hasConfirmedAirDate: Bool {
        DateParser.parseISO8601(airDate) != nil
    }

    nonisolated func asDomain(provider: MediaProvider, showID: Int, seasonNumber: Int) -> ShowEpisode {
        ShowEpisode(
            provider: provider,
            showID: showID,
            seasonNumber: seasonNumber,
            number: episodeNumber,
            title: name,
            overview: overview,
            airDate: DateParser.parseISO8601(airDate),
            stillURL: tmdbImageURL(path: stillPath, size: "w300"),
            runtimeMinutes: runtime
        )
    }

    nonisolated func asEpisodeDetails(
        provider: MediaProvider,
        showID: Int,
        seasonNumber: Int
    ) -> EpisodeDetails {
        EpisodeDetails(
            episode: asDomain(provider: provider, showID: showID, seasonNumber: seasonNumber),
            voteAverage: voteAverage
        )
    }
}

private func seasonOrder(_ lhs: SeasonSummary, _ rhs: SeasonSummary) -> Bool {
    let lhsIsSpecial = lhs.number == 0
    let rhsIsSpecial = rhs.number == 0
    if lhsIsSpecial != rhsIsSpecial {
        return !lhsIsSpecial
    }
    return lhs.number < rhs.number
}

nonisolated func tmdbImageURL(path: String?, size: String) -> URL? {
    path.flatMap { URL(string: "https://image.tmdb.org/t/p/\(size)\($0)") }
}
