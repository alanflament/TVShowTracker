//
//  JikanSearchAnime.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

struct JikanSearchAnime: Decodable {
    enum CodingKeys: String, CodingKey {
        case id = "mal_id"
        case title
        case titleEnglish = "title_english"
    }

    let id: Int
    let title: String
    let titleEnglish: String?
}
