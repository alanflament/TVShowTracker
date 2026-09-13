//
//  AniListDetailsInstallment.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

struct AniListDetailsInstallment: Decodable {
    let id: Int
    let title: AniListTitle
    let format: String?
    let status: String?
    let episodes: Int?
    let startDate: AniListFuzzyDate
    let relations: AniListDetailsRelations?
}
