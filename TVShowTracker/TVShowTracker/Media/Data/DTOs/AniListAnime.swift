//
//  AniListAnime.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
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
