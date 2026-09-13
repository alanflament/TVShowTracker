//
//  TMDBEpisode.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

nonisolated struct TMDBEpisode: Decodable {
    enum CodingKeys: String, CodingKey {
        case name, overview, runtime
        case episodeNumber = "episode_number"
        case airDate = "air_date"
        case stillPath = "still_path"
        case voteAverage = "vote_average"
    }

    let episodeNumber: Int
    let name: String
    let overview: String?
    let airDate: String?
    let stillPath: String?
    let runtime: Int?
    let voteAverage: Double?
}
