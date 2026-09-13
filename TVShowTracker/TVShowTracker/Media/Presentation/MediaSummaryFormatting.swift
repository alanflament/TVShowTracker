//
//  MediaSummaryFormatting.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

enum MediaSummaryFormatting {
    static func metadata(kind: MediaKind, releaseYear: Int?, episodeCount: Int?) -> String {
        var values = [kind.displayName]
        if let releaseYear {
            values.append(String(releaseYear))
        }
        if let episodeCount {
            values.append("\(episodeCount) episodes")
        }
        return values.joined(separator: " · ")
    }
}
