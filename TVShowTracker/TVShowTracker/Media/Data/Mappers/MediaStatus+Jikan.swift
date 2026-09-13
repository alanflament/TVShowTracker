//
//  MediaStatus+Jikan.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

extension MediaStatus {
    init?(jikanStatus: String?) {
        switch jikanStatus {
        case "Currently Airing":
            self = .airing
        case "Finished Airing":
            self = .finished
        case "Not yet aired":
            self = .upcoming
        default:
            return nil
        }
    }
}
