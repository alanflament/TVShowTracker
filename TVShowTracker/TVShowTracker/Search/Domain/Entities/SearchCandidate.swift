//
//  SearchCandidate.swift
//  TVShowTracker
//
//  Created by Alan Flament on 30/07/2026.
//

import Foundation

enum SearchProvider: String, Hashable, Sendable {
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

enum SearchMediaKind: String, Hashable, Sendable {
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

enum SearchMediaStatus: String, Hashable, Sendable {
    case airing
    case finished
    case upcoming
    case cancelled
    case hiatus
}

struct SearchCandidate: Identifiable, Hashable, Sendable {
    let provider: SearchProvider
    let providerID: Int
    let kind: SearchMediaKind
    let title: String
    let alternateTitle: String?
    let posterURL: URL?
    let releaseYear: Int?
    let totalEpisodeCount: Int?
    let status: SearchMediaStatus?
    let nextEpisodeNumber: Int?
    let nextEpisodeAirDate: Date?

    var id: String {
        "\(provider.rawValue):\(providerID)"
    }

    var metadata: String {
        var values = [kind.displayName]

        if let releaseYear {
            values.append(String(releaseYear))
        }

        if let totalEpisodeCount {
            values.append("\(totalEpisodeCount) episodes")
        }

        return values.joined(separator: " · ")
    }
}
