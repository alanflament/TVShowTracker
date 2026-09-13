//
//  TMDBSeasonSummary.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

struct TMDBSeasonSummary: Decodable {
    enum CodingKeys: String, CodingKey {
        case id, name
        case seasonNumber = "season_number"
        case episodeCount = "episode_count"
        case airDate = "air_date"
    }

    let id: Int
    let name: String
    let seasonNumber: Int
    let episodeCount: Int
    let airDate: String?
}
