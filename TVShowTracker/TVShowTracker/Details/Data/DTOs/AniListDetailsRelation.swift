//
//  AniListDetailsRelation.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

struct AniListDetailsRelation: Decodable {
    let relationType: String
    let node: AniListDetailsInstallment
}
