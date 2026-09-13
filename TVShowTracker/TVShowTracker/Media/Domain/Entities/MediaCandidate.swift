//
//  MediaCandidate.swift
//  TVShowTracker
//
//  Created by Alan Flament on 30/07/2026.
//

import Foundation

nonisolated struct MediaCandidate: Identifiable, Hashable, Sendable {
    let provider: MediaProvider
    let providerID: Int
    let kind: MediaKind
    let title: String
    let alternateTitle: String?
    let posterURL: URL?
    let releaseYear: Int?
    let totalEpisodeCount: Int?
    let status: MediaStatus?
    let nextEpisodeNumber: Int?
    let nextEpisodeAirDate: Date?
    let animeInstallments: [AnimeInstallmentReference]

    init(
        provider: MediaProvider,
        providerID: Int,
        kind: MediaKind,
        title: String,
        alternateTitle: String?,
        posterURL: URL?,
        releaseYear: Int?,
        totalEpisodeCount: Int?,
        status: MediaStatus?,
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

    func updating(with details: ShowDetails) -> MediaCandidate {
        MediaCandidate(
            provider: provider,
            providerID: providerID,
            kind: kind,
            title: details.title,
            alternateTitle: details.alternateTitle,
            posterURL: details.posterURL ?? posterURL,
            releaseYear: details.releaseYear ?? releaseYear,
            totalEpisodeCount: details.totalEpisodeCount ?? totalEpisodeCount,
            status: details.status ?? status,
            nextEpisodeNumber: nextEpisodeNumber,
            nextEpisodeAirDate: nextEpisodeAirDate,
            animeInstallments: details.animeInstallments ?? animeInstallments
        )
    }
}
