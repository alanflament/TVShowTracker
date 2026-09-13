//
//  AniListData.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

struct AniListData: Decodable {
    enum CodingKeys: String, CodingKey {
        case page = "Page"
    }

    let page: AniListPage
}
