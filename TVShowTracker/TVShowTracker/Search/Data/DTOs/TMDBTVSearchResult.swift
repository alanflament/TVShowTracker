//
//  TMDBTVSearchResult.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

struct TMDBTVSearchResult: Decodable {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case originalName = "original_name"
        case posterPath = "poster_path"
        case firstAirDate = "first_air_date"
    }

    let id: Int
    let name: String
    let originalName: String?
    let posterPath: String?
    let firstAirDate: String?
}
