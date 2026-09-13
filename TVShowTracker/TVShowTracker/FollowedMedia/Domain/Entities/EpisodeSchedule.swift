//
//  EpisodeSchedule.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

nonisolated struct EpisodeSchedule: Identifiable, Hashable, Sendable, Codable {
    let id: String
    let seasons: [ShowSeason]
    let refreshedAt: Date

    init(itemID: String, seasons: [ShowSeason], refreshedAt: Date = .now) {
        id = itemID
        self.seasons = seasons.sorted(by: seasonOrder)
        self.refreshedAt = refreshedAt
    }
}

private nonisolated func seasonOrder(_ lhs: ShowSeason, _ rhs: ShowSeason) -> Bool {
    if lhs.isSpecial != rhs.isSpecial {
        return !lhs.isSpecial
    }
    return lhs.number < rhs.number
}
