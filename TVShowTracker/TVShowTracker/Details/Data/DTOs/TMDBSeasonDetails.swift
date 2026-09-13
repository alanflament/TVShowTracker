//
//  TMDBSeasonDetails.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

nonisolated struct TMDBSeasonDetails: Decodable {
    enum CodingKeys: String, CodingKey {
        case name, episodes
        case seasonNumber = "season_number"
    }

    let seasonNumber: Int
    let name: String
    let episodes: [TMDBEpisode]
}
