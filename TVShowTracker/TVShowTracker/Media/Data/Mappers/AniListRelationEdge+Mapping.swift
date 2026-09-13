//
//  AniListRelationEdge+Mapping.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

extension AniListRelationEdge {
    var connectsSeasons: Bool {
        ["PREQUEL", "SEQUEL"].contains(relationType) && node.isSeasonInstallment
    }
}
