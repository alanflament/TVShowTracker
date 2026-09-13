//
//  TMDBShowDetails.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

struct TMDBShowDetails: Decodable {
    enum CodingKeys: String, CodingKey {
        case id, name, overview, status, genres, seasons
        case originalName = "original_name"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case firstAirDate = "first_air_date"
        case numberOfEpisodes = "number_of_episodes"
    }

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
}
