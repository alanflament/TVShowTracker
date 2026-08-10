//
//  TMDBDTVTOs.swift
//  TVShowTracker
//
//  Created by Alan Flament on 10/08/2026.
//

struct TMDBTVSearchResponse: Decodable {
    let results: [TMDBTVSearchResult]
}

struct TMDBTVSearchResult: Decodable {
    let id: Int
    let name: String
    let originalName: String?
    let posterPath: String?
    let firstAirDate: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case originalName = "original_name"
        case posterPath = "poster_path"
        case firstAirDate = "first_air_date"
    }
}
