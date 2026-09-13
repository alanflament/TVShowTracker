//
//  TMDBEpisode+Mapping.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

extension TMDBEpisode {
    nonisolated var hasConfirmedAirDate: Bool {
        DateParser.parseISO8601(airDate) != nil
    }

    nonisolated func asDomain(provider: MediaProvider, showID: Int, seasonNumber: Int) -> ShowEpisode {
        ShowEpisode(
            provider: provider,
            showID: showID,
            seasonNumber: seasonNumber,
            number: episodeNumber,
            title: name,
            overview: overview,
            airDate: DateParser.parseISO8601(airDate),
            stillURL: MediaImageURL.tmdb(path: stillPath, size: "w300"),
            runtimeMinutes: runtime
        )
    }

    nonisolated func asEpisodeDetails(
        provider: MediaProvider,
        showID: Int,
        seasonNumber: Int
    ) -> EpisodeDetails {
        EpisodeDetails(
            episode: asDomain(provider: provider, showID: showID, seasonNumber: seasonNumber),
            voteAverage: voteAverage
        )
    }
}
