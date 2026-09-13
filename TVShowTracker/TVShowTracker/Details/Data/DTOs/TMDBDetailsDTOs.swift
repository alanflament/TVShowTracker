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
}

nonisolated struct TMDBSeasonDetails: Decodable {
    let seasonNumber: Int
    let name: String
    let episodes: [TMDBEpisode]

    enum CodingKeys: String, CodingKey {
        case name, episodes
        case seasonNumber = "season_number"
    }
}

nonisolated struct TMDBEpisode: Decodable {
    let episodeNumber: Int
    let name: String
    let overview: String?
    let airDate: String?
    let stillPath: String?
    let runtime: Int?
    let voteAverage: Double?

    enum CodingKeys: String, CodingKey {
        case name, overview, runtime
        case episodeNumber = "episode_number"
        case airDate = "air_date"
        case stillPath = "still_path"
        case voteAverage = "vote_average"
    }
}
