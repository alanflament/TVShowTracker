//
//  SearchCandidate.swift
//  TVShowTracker
//
//  Created by Alan Flament on 30/07/2026.
//

import Foundation

struct SearchCandidate: Identifiable, Hashable, Sendable {
    let provider: SearchProvider
    let providerID: Int
    let kind: SearchMediaKind
    let title: String
    let alternateTitle: String?
    let posterURL: URL?
    let releaseYear: Int?
    let totalEpisodeCount: Int?
    let status: SearchMediaStatus?
    let nextEpisodeNumber: Int?
    let nextEpisodeAirDate: Date?
    let animeInstallments: [AnimeInstallmentReference]

    init(
        provider: SearchProvider,
        providerID: Int,
        kind: SearchMediaKind,
        title: String,
        alternateTitle: String?,
        posterURL: URL?,
        releaseYear: Int?,
        totalEpisodeCount: Int?,
        status: SearchMediaStatus?,
        nextEpisodeNumber: Int?,
        nextEpisodeAirDate: Date?,
        animeInstallments: [AnimeInstallmentReference] = []
    ) {
        self.provider = provider
        self.providerID = providerID
        self.kind = kind
        self.title = title
        self.alternateTitle = alternateTitle
        self.posterURL = posterURL
        self.releaseYear = releaseYear
        self.totalEpisodeCount = totalEpisodeCount
        self.status = status
        self.nextEpisodeNumber = nextEpisodeNumber
        self.nextEpisodeAirDate = nextEpisodeAirDate
        self.animeInstallments = animeInstallments
    }

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
