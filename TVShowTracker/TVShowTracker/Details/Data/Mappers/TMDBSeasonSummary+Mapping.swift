//
//  TMDBSeasonSummary+Mapping.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

extension TMDBSeasonSummary {
    func asDomain(provider: MediaProvider, showID: Int) -> SeasonSummary {
        SeasonSummary(
            provider: provider,
            showID: showID,
            number: seasonNumber,
            name: name,
            episodeCount: episodeCount,
            airDate: DateParser.parseISO8601(airDate)
        )
    }
}
