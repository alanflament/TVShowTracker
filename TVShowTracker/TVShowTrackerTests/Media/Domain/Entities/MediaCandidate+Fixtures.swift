//
//  MediaCandidate+Fixtures.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

extension MediaCandidate {
    static func tvShow(id: Int, title: String) -> MediaCandidate {
        MediaCandidate(
            provider: .tmdb,
            providerID: id,
            kind: .tvShow,
            title: title,
            alternateTitle: nil,
            posterURL: nil,
            releaseYear: nil,
            totalEpisodeCount: nil,
            status: nil,
            nextEpisodeNumber: nil,
            nextEpisodeAirDate: nil
        )
    }

    static func anime(id: Int, title: String) -> MediaCandidate {
        MediaCandidate(
            provider: .aniList,
            providerID: id,
            kind: .anime,
            title: title,
            alternateTitle: nil,
            posterURL: nil,
            releaseYear: nil,
            totalEpisodeCount: nil,
            status: nil,
            nextEpisodeNumber: nil,
            nextEpisodeAirDate: nil
        )
    }

    static func jikanAnime(id: Int, title: String) -> MediaCandidate {
        MediaCandidate(
            provider: .jikan,
            providerID: id,
            kind: .anime,
            title: title,
            alternateTitle: nil,
            posterURL: nil,
            releaseYear: nil,
            totalEpisodeCount: nil,
            status: nil,
            nextEpisodeNumber: nil,
            nextEpisodeAirDate: nil
        )
    }
}
