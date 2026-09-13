//
//  JikanDetailsAnime.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

struct JikanDetailsAnime: Decodable {
    enum CodingKeys: String, CodingKey {
        case id = "mal_id"
        case title
        case titleEnglish = "title_english"
        case titleJapanese = "title_japanese"
        case synopsis, images, episodes, duration, status, aired, genres
    }

    let id: Int
    let title: String
    let titleEnglish: String?
    let titleJapanese: String?
    let synopsis: String?
    let images: JikanImages
    let episodes: Int?
    let duration: String?
    let status: String?
    let aired: JikanAired
    let genres: [JikanNamedResource]
}
