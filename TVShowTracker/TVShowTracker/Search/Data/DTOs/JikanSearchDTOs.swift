//
//  JikanSearchDTOs.swift
//  TVShowTracker
//
//  Created by Alan Flament on 10/08/2026.
//

import Foundation

struct JikanSearchResponse: Decodable {
    let data: [JikanAnime]
}

struct JikanAnime: Decodable {
    let id: Int
    let title: String
    let titleEnglish: String?
    let titleJapanese: String?
    let titleSynonyms: [String]
    let images: JikanImages
    let episodes: Int?
    let status: String?
    let aired: JikanAired

    enum CodingKeys: String, CodingKey {
        case id = "mal_id"
        case title
        case titleEnglish = "title_english"
        case titleJapanese = "title_japanese"
        case titleSynonyms = "title_synonyms"
        case images
        case episodes
        case status
        case aired
    }
}
