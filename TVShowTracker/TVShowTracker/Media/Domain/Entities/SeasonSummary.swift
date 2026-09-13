//
//  SeasonSummary.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

nonisolated struct SeasonSummary: Identifiable, Hashable, Sendable {
    let provider: MediaProvider
    let showID: Int
    let number: Int
    let name: String
    let episodeCount: Int
    let airDate: Date?

    var id: String {
        "\(provider.rawValue):\(showID):season:\(number)"
    }
}
