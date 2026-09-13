//
//  AniListSearchDTOs.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

struct AniListData: Decodable {
    let page: AniListPage

    enum CodingKeys: String, CodingKey {
        case page = "Page"
    }
}

struct AniListPage: Decodable {
    let media: [AniListAnime]
}
