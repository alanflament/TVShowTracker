//
//  ShowEpisode.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

nonisolated struct ShowEpisode: Codable, Identifiable, Hashable, Sendable {
    let provider: SearchProvider
    let showID: Int
    let seasonNumber: Int
    let number: Int
    let title: String
    let overview: String?
    let airDate: Date?
    let releaseDatePrecision: EpisodeReleaseDatePrecision
    let stillURL: URL?
    let runtimeMinutes: Int?

    nonisolated init(
        provider: SearchProvider,
        showID: Int,
        seasonNumber: Int,
        number: Int,
        title: String,
        overview: String?,
        airDate: Date?,
        releaseDatePrecision: EpisodeReleaseDatePrecision = .day,
        stillURL: URL?,
        runtimeMinutes: Int?
    ) {
        self.provider = provider
        self.showID = showID
        self.seasonNumber = seasonNumber
        self.number = number
        self.title = title
        self.overview = overview
        self.airDate = airDate
        self.releaseDatePrecision = releaseDatePrecision
        self.stillURL = stillURL
        self.runtimeMinutes = runtimeMinutes
    }

    var id: String {
        "\(provider.rawValue):\(showID):\(seasonNumber):\(number)"
    }

    var isReleased: Bool {
        isReleased(at: .now)
    }

    var formattedDuration: String? {
        runtimeMinutes.flatMap { EpisodeDurationFormatter.format(minutes: $0) }
    }

    func isReleased(at date: Date) -> Bool {
        guard let airDate else {
            // Anime providers synthesize known episode counts without always providing per-episode dates.
            return provider != .tmdb
        }
        return airDate <= date
    }
}
