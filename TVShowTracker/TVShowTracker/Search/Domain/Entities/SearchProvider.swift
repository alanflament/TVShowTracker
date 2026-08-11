//
//  SearchProvider.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

enum SearchProvider: String, Codable, Hashable, Sendable {
    case tmdb
    case aniList
    case jikan

    var displayName: String {
        switch self {
        case .tmdb:
            "TMDB"
        case .aniList:
            "AniList"
        case .jikan:
            "MyAnimeList (via Jikan)"
        }
    }
}
