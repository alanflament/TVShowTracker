//
//  JikanEpisode+Mapping.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

extension JikanEpisode {
    func asDomain(
        provider: MediaProvider,
        showID: Int,
        runtimeMinutes: Int? = nil
    ) -> ShowEpisode {
        ShowEpisode(
            provider: provider,
            showID: showID,
            seasonNumber: 1,
            number: number,
            title: title ?? "Episode \(number)",
            overview: nil,
            airDate: DateParser.parseISO8601(aired),
            stillURL: nil,
            runtimeMinutes: runtimeMinutes
        )
    }
}
