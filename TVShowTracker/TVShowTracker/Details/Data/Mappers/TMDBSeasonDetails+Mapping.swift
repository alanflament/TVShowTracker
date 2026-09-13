//
//  TMDBSeasonDetails+Mapping.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

extension TMDBSeasonDetails {
    nonisolated func asDomain(provider: MediaProvider, showID: Int) -> ShowSeason {
        ShowSeason(
            provider: provider,
            showID: showID,
            number: seasonNumber,
            name: name,
            episodes: episodes.compactMap {
                // TMDB can publish placeholder episode records before a schedule is confirmed.
                guard $0.hasConfirmedAirDate else {
                    return nil
                }
                return $0.asDomain(provider: provider, showID: showID, seasonNumber: seasonNumber)
            }
        )
    }
}
