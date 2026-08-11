//
//  ShowDetails.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

struct ShowDetails: Identifiable, Hashable, Sendable {
    let provider: SearchProvider
    let providerID: Int
    let kind: SearchMediaKind
    let title: String
    let alternateTitle: String?
    let overview: String?
    let posterURL: URL?
    let backdropURL: URL?
    let releaseYear: Int?
    let status: SearchMediaStatus?
    let totalEpisodeCount: Int?
    let genres: [String]
    let seasonSummaries: [SeasonSummary]

    var id: String {
        "\(provider.rawValue):\(providerID)"
    }

    var metadata: String {
        var values = [kind.displayName]
        if let releaseYear {
            values.append(String(releaseYear))
        }
        if let totalEpisodeCount {
            values.append("\(totalEpisodeCount) episodes")
        }
        return values.joined(separator: " · ")
    }
}
