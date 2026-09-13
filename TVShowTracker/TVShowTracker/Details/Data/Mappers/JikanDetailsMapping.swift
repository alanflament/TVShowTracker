//
//  JikanDetailsMapping.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

extension JikanDetailsAnime {
    var asDomain: ShowDetails {
        ShowDetails(
            provider: .jikan,
            providerID: id,
            kind: .anime,
            title: titleEnglish ?? title,
            alternateTitle: titleJapanese,
            overview: synopsis,
            posterURL: images.jpg.largeImageURL ?? images.jpg.imageURL,
            backdropURL: nil,
            releaseYear: aired.from.flatMap { Int($0.prefix(4)) },
            status: MediaStatus(jikanStatus: status),
            totalEpisodeCount: episodes,
            genres: genres.map(\.name),
            seasonSummaries: episodes.map {
                [SeasonSummary(
                    provider: .jikan,
                    showID: id,
                    number: 1,
                    name: "Episodes",
                    episodeCount: $0,
                    airDate: nil
                )]
            } ?? []
        )
    }

    var episodeDurationMinutes: Int? {
        guard let duration else {
            return nil
        }

        let components = duration
            .lowercased()
            .replacingOccurrences(of: ".", with: "")
            .split(separator: " ")
        var totalMinutes = 0
        var foundDuration = false

        for index in components.indices {
            guard let value = Int(components[index]), components.indices.contains(index + 1) else {
                continue
            }

            let unit = components[index + 1]
            if unit.hasPrefix("hr") {
                totalMinutes += value * 60
                foundDuration = true
            } else if unit.hasPrefix("min") {
                totalMinutes += value
                foundDuration = true
            }
        }

        return foundDuration && totalMinutes > 0 ? totalMinutes : nil
    }
}

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
