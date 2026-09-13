//
//  JikanEpisode.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

struct JikanEpisode: Decodable {
    enum CodingKeys: String, CodingKey {
        case number = "mal_id"
        case title, aired
    }

    let number: Int
    let title: String?
    let aired: String?
}
