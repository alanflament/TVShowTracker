//
//  AniListDetailsDTOs.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

struct AniListDetailsData: Decodable {
    let media: AniListDetailsAnime?

    enum CodingKeys: String, CodingKey {
        case media = "Media"
    }
}

struct AniListDetailsAnime: Decodable {
    let id: Int
    let title: AniListTitle
    let description: String?
    let coverImage: AniListCoverImage
    let status: String?
    let episodes: Int?
    let duration: Int?
    let startDate: AniListFuzzyDate
    let genres: [String]
    let airingSchedule: AniListAiringSchedule?
    let format: String?
    let relations: AniListDetailsRelations?
}

struct AniListDetailsRelations: Decodable {
    let edges: [AniListDetailsRelation]
}

struct AniListDetailsRelation: Decodable {
    let relationType: String
    let node: AniListDetailsInstallment
}

struct AniListDetailsInstallment: Decodable {
    let id: Int
    let title: AniListTitle
    let format: String?
    let status: String?
    let episodes: Int?
    let startDate: AniListFuzzyDate
    let relations: AniListDetailsRelations?
}

struct AniListAiringSchedule: Decodable {
    let nodes: [AniListAiringNode]
}

struct AniListAiringNode: Decodable {
    let episode: Int
    let airingAt: Int
}
