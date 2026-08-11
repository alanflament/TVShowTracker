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
    let animeInstallments: [AnimeInstallmentReference]

    init(
        provider: SearchProvider,
        providerID: Int,
        kind: SearchMediaKind,
        title: String,
        alternateTitle: String?,
        posterURL: URL?,
        releaseYear: Int?,
        totalEpisodeCount: Int?,
        status: SearchMediaStatus?,
        nextEpisodeNumber: Int?,
        nextEpisodeAirDate: Date?,
        animeInstallments: [AnimeInstallmentReference] = []
    ) {
        self.provider = provider
        self.providerID = providerID
        self.kind = kind
        self.title = title
        self.alternateTitle = alternateTitle
        self.posterURL = posterURL
        self.releaseYear = releaseYear
        self.totalEpisodeCount = totalEpisodeCount
        self.status = status
        self.nextEpisodeNumber = nextEpisodeNumber
        self.nextEpisodeAirDate = nextEpisodeAirDate
        self.animeInstallments = animeInstallments
    }

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

struct AnimeInstallmentReference: Hashable, Sendable {
    let providerID: Int
    let title: String
    let releaseYear: Int?
    let releaseMonth: Int?
    let releaseDay: Int?
    let episodeCount: Int?
    let status: SearchMediaStatus?
}
