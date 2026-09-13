//
//  ShowEpisode+Fixtures.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

extension ShowEpisode {
    static func tvShow(id: Int, season: Int, number: Int) -> ShowEpisode {
        ShowEpisode(
            provider: .tmdb,
            showID: id,
            seasonNumber: season,
            number: number,
            title: "Episode \(number)",
            overview: nil,
            airDate: .distantPast,
            stillURL: nil,
            runtimeMinutes: nil
        )
    }
}
