//
//  TMDBMediaStatusMapping.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

extension SearchMediaStatus {
    init?(tmdbStatus: String?) {
        switch tmdbStatus {
        case "Returning Series", "In Production":
            self = .airing
        case "Ended", "Canceled":
            self = .finished
        case "Planned", "Pilot":
            self = .upcoming
        default:
            return nil
        }
    }
}
