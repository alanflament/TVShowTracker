//
//  SearchMediaKind.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

enum SearchMediaKind: String, Codable, Hashable, Sendable {
    case tvShow
    case anime

    var displayName: String {
        switch self {
        case .tvShow:
            "TV series"
        case .anime:
            "Anime"
        }
    }
}
