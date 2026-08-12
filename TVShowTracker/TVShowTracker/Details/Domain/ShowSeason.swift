//
//  ShowSeason.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

struct ShowSeason: Codable, Identifiable, Hashable, Sendable {
    let provider: SearchProvider
    let showID: Int
    let number: Int
    let name: String
    let episodes: [ShowEpisode]

    var isSpecial: Bool {
        number == 0
    }

    var displayName: String {
        isSpecial ? "Specials" : name
    }

    var id: String {
        "\(provider.rawValue):\(showID):season:\(number)"
    }
}
