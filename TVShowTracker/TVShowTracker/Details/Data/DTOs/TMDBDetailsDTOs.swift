//
//  TMDBDetailsDTOs.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

struct TMDBShowDetails: Decodable {
    let id: Int
    let name: String
    let originalName: String?
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let firstAirDate: String?
    let status: String?
    let numberOfEpisodes: Int?
    let genres: [TMDBGenre]
    let seasons: [TMDBSeasonSummary]

    enum CodingKeys: String, CodingKey {
        case id, name, overview, status, genres, seasons
        case originalName = "original_name"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case firstAirDate = "first_air_date"
        case numberOfEpisodes = "number_of_episodes"
    }

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
            status: SearchMediaStatus(tmdbStatus: status),
            totalEpisodeCount: numberOfEpisodes,
            genres: genres.map(\.name),
            seasonSummaries: seasons
                .map { $0.asDomain(provider: .tmdb, showID: id) }
                .sorted(by: seasonOrder)
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

struct TMDBGenre: Decodable {
    let name: String
}

struct TMDBSeasonSummary: Decodable {
    let id: Int
    let name: String
    let seasonNumber: Int
    let episodeCount: Int
    let airDate: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case seasonNumber = "season_number"
        case episodeCount = "episode_count"
        case airDate = "air_date"
    }

    func asDomain(provider: SearchProvider, showID: Int) -> SeasonSummary {
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

nonisolated struct TMDBSeasonDetails: Decodable {
    let seasonNumber: Int
    let name: String
    let episodes: [TMDBEpisode]

    enum CodingKeys: String, CodingKey {
        case name, episodes
        case seasonNumber = "season_number"
    }

    nonisolated func asDomain(provider: SearchProvider, showID: Int) -> ShowSeason {
        ShowSeason(
            provider: provider,
            showID: showID,
            number: seasonNumber,
            name: name,
            episodes: episodes.map { $0.asDomain(provider: provider, showID: showID, seasonNumber: seasonNumber) }
        )
    }
}

nonisolated struct TMDBEpisode: Decodable {
    let episodeNumber: Int
    let name: String
    let overview: String?
    let airDate: String?
    let stillPath: String?
    let runtime: Int?

    enum CodingKeys: String, CodingKey {
        case name, overview, runtime
        case episodeNumber = "episode_number"
        case airDate = "air_date"
        case stillPath = "still_path"
    }

    func asDomain(provider: SearchProvider, showID: Int, seasonNumber: Int) -> ShowEpisode {
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
}

nonisolated func tmdbImageURL(path: String?, size: String) -> URL? {
    path.flatMap { URL(string: "https://image.tmdb.org/t/p/\(size)\($0)") }
}
