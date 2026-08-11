//
//  ShowEpisode.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

struct ShowEpisode: Identifiable, Hashable, Sendable {
    let provider: SearchProvider
    let showID: Int
    let seasonNumber: Int
    let number: Int
    let title: String
    let overview: String?
    let airDate: Date?
    let stillURL: URL?
    let runtimeMinutes: Int?

    var id: String {
        "\(provider.rawValue):\(showID):\(seasonNumber):\(number)"
    }

    var isReleased: Bool {
        guard let airDate else {
            return true
        }
        return airDate <= .now
    }
}
