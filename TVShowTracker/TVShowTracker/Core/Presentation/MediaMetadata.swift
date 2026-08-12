//
//  MediaMetadata.swift
//  TVShowTracker
//
//  Created by Alan Flament on 12/08/2026.
//

enum MediaMetadata {
    static func text(releaseYear: Int?, totalEpisodeCount: Int?) -> String {
        [
            releaseYear.map(String.init),
            totalEpisodeCount.map { "\($0) episodes" }
        ]
        .compactMap { $0 }
        .joined(separator: " · ")
    }
}
