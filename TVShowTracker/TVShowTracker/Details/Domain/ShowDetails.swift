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
    let animeInstallments: [AnimeInstallmentReference]?

    init(
        provider: SearchProvider,
        providerID: Int,
        kind: SearchMediaKind,
        title: String,
        alternateTitle: String?,
        overview: String?,
        posterURL: URL?,
        backdropURL: URL?,
        releaseYear: Int?,
        status: SearchMediaStatus?,
        totalEpisodeCount: Int?,
        genres: [String],
        seasonSummaries: [SeasonSummary],
        animeInstallments: [AnimeInstallmentReference]? = nil
    ) {
        self.provider = provider
        self.providerID = providerID
        self.kind = kind
        self.title = title
        self.alternateTitle = alternateTitle
        self.overview = overview
        self.posterURL = posterURL
        self.backdropURL = backdropURL
        self.releaseYear = releaseYear
        self.status = status
        self.totalEpisodeCount = totalEpisodeCount
        self.genres = genres
        self.seasonSummaries = seasonSummaries
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
