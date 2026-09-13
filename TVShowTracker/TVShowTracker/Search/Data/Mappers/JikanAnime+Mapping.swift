//
//  JikanAnime+Mapping.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

extension JikanAnime {
    var preferredTitle: String {
        titleEnglish ?? title
    }

    var alternateTitle: String? {
        ([title, titleJapanese] + titleSynonyms)
            .compactMap { $0 }
            .first { $0 != preferredTitle }
    }

    var releaseYear: Int? {
        aired.from.flatMap { Int($0.prefix(4)) }
    }
}
