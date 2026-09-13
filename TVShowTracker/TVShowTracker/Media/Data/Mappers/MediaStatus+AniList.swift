//
//  MediaStatus+AniList.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

extension MediaStatus {
    init?(anilistStatus: String?) {
        switch anilistStatus {
        case "RELEASING":
            self = .airing
        case "FINISHED":
            self = .finished
        case "NOT_YET_RELEASED":
            self = .upcoming
        case "CANCELLED":
            self = .cancelled
        case "HIATUS":
            self = .hiatus
        default:
            return nil
        }
    }
}
