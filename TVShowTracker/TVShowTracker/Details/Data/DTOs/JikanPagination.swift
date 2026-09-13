//
//  JikanPagination.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

struct JikanPagination: Decodable {
    enum CodingKeys: String, CodingKey {
        case lastPage = "last_visible_page"
    }

    let lastPage: Int
}
