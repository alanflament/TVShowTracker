//
//  AniListMediaDTOs.swift
//  TVShowTracker
//
//  Created by Alan Flament on 10/08/2026.
//

import Foundation

struct AniListAnime: Decodable {
    let id: Int
    let title: AniListTitle
    let coverImage: AniListCoverImage
    let format: String?
    let status: String?
    let episodes: Int?
    let startDate: AniListFuzzyDate
    let nextAiringEpisode: AniListAiringEpisode?
    let relations: AniListRelations?
}

struct AniListRelations: Decodable {
    let edges: [AniListRelationEdge]
}

struct AniListRelationEdge: Decodable {
    let relationType: String
    let node: AniListAnime
}

struct AniListTitle: Decodable {
    let userPreferred: String?
    let english: String?
    let romaji: String?
    let native: String?
}

struct AniListCoverImage: Decodable {
    let large: URL?
    let medium: URL?
}

struct AniListFuzzyDate: Decodable {
    let year: Int?
    let month: Int?
    let day: Int?
}

struct AniListAiringEpisode: Decodable {
    let episode: Int
    let airingAt: Int
}

struct AniListGraphQLError: Decodable {
    let message: String
}
