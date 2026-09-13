//
//  TMDBMediaStatusMapping.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

extension MediaStatus {
    init?(tmdbStatus: String?) {
        switch tmdbStatus {
        case "Returning Series", "In Production":
            self = .airing
        case "Ended":
            self = .finished
        case "Canceled":
            self = .cancelled
        case "Planned", "Pilot":
            self = .upcoming
        default:
            return nil
        }
    }
}
