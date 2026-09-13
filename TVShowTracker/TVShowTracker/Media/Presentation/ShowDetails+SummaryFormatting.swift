//
//  ShowDetails+SummaryFormatting.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

extension ShowDetails {
    var metadata: String {
        MediaSummaryFormatting.metadata(kind: kind, releaseYear: releaseYear, episodeCount: totalEpisodeCount)
    }
}
