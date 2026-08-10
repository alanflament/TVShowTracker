//
//  AniListDTOs.swift
//  TVShowTracker
//
//  Created by Alan Flament on 10/08/2026.
//

import Foundation

struct AniListData: Decodable {
    let page: AniListPage

    enum CodingKeys: String, CodingKey {
        case page = "Page"
    }
}

struct AniListPage: Decodable {
    let media: [AniListAnime]
}

struct AniListAnime: Decodable {
    let id: Int
    let title: AniListTitle
    let coverImage: AniListCoverImage
    let status: String?
    let episodes: Int?
    let startDate: AniListFuzzyDate
    let nextAiringEpisode: AniListAiringEpisode?
}

struct AniListTitle: Decodable {
    let userPreferred: String?
    let english: String?
    let romaji: String?
    let native: String?

    var preferredTitle: String {
        userPreferred ?? english ?? romaji ?? native ?? "Untitled"
    }

    var alternateTitle: String? {
        [english, romaji, native]
            .compactMap { $0 }
            .first { $0 != preferredTitle }
    }
}

struct AniListCoverImage: Decodable {
    let large: URL?
    let medium: URL?
}

struct AniListFuzzyDate: Decodable {
    let year: Int?
}

struct AniListAiringEpisode: Decodable {
    let episode: Int
    let airingAt: Int
}

struct AniListGraphQLError: Decodable {
    let message: String
}

enum AniListAPIError: LocalizedError, Sendable {
    case queryFailed(String)

    var errorDescription: String? {
        switch self {
        case let .queryFailed(message):
            message
        }
    }
}

extension SearchMediaStatus {
    init?(anilistStatus: String?) {
        switch anilistStatus {
        case "RELEASING":
            self = .airing
        case "FINISHED":
            self = .finished
        case "NOT_YET_RELEASED":
            self = .upcoming
        case "CANCELLED":
            self = .cancelled
        case "HIATUS":
            self = .hiatus
        default:
            return nil
        }
    }
}
