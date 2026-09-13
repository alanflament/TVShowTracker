//
//  ShowDetails.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

nonisolated struct ShowDetails: Identifiable, Hashable, Sendable {
    let provider: MediaProvider
    let providerID: Int
    let kind: MediaKind
    let title: String
    let alternateTitle: String?
    let overview: String?
    let posterURL: URL?
    let backdropURL: URL?
    let releaseYear: Int?
    let status: MediaStatus?
    let totalEpisodeCount: Int?
    let genres: [String]
    let seasonSummaries: [SeasonSummary]
    let animeInstallments: [AnimeInstallmentReference]?

    init(
        provider: MediaProvider,
        providerID: Int,
        kind: MediaKind,
        title: String,
        alternateTitle: String?,
        overview: String?,
        posterURL: URL?,
        backdropURL: URL?,
        releaseYear: Int?,
        status: MediaStatus?,
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
}
