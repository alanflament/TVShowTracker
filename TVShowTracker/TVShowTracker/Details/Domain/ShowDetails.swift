//
//  ShowDetails.swift
//  TVShowTracker
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

struct SeasonSummary: Identifiable, Hashable, Sendable {
    let provider: SearchProvider
    let showID: Int
    let number: Int
    let name: String
    let episodeCount: Int
    let airDate: Date?

    var id: String {
        "\(provider.rawValue):\(showID):season:\(number)"
    }
}

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

struct ShowSeason: Identifiable, Hashable, Sendable {
    let provider: SearchProvider
    let showID: Int
    let number: Int
    let name: String
    let episodes: [ShowEpisode]

    var id: String {
        "\(provider.rawValue):\(showID):season:\(number)"
    }
}
