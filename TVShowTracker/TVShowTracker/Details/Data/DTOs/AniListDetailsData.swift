//
//  AniListDetailsData.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

struct AniListDetailsData: Decodable {
    enum CodingKeys: String, CodingKey {
        case media = "Media"
    }

    let media: AniListDetailsAnime?
}
