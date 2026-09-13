//
//  AniListTitle+Mapping.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

extension AniListTitle {
    var preferredTitle: String {
        userPreferred ?? english ?? romaji ?? native ?? "Untitled"
    }

    var alternateTitle: String? {
        [english, romaji, native]
            .compactMap { $0 }
            .first { $0 != preferredTitle }
    }
}
