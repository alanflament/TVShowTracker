//
//  AniListRelationEdge.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

struct AniListRelationEdge: Decodable {
    let relationType: String
    let node: AniListAnime
}
