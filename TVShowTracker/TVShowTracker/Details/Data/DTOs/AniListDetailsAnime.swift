//
//  AniListDetailsAnime.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

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
