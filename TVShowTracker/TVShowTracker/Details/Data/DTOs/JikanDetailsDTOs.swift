//
//  JikanDetailsDTOs.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

struct JikanSearchEnvelope: Decodable {
    let data: [JikanSearchAnime]
}

struct JikanSearchAnime: Decodable {
    let id: Int
    let title: String
    let titleEnglish: String?

    enum CodingKeys: String, CodingKey {
        case id = "mal_id"
        case title
        case titleEnglish = "title_english"
    }
}

struct JikanEnvelope<Response: Decodable>: Decodable {
    let data: Response
}

struct JikanDetailsAnime: Decodable {
    let id: Int
    let title: String
    let titleEnglish: String?
    let titleJapanese: String?
    let synopsis: String?
    let images: JikanImages
    let episodes: Int?
    let duration: String?
    let status: String?
    let aired: JikanAired
    let genres: [JikanNamedResource]

    enum CodingKeys: String, CodingKey {
        case id = "mal_id"
        case title
        case titleEnglish = "title_english"
        case titleJapanese = "title_japanese"
        case synopsis, images, episodes, duration, status, aired, genres
    }

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
            status: SearchMediaStatus(jikanStatus: status),
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

struct JikanNamedResource: Decodable {
    let name: String
}

struct JikanEpisodePage: Decodable {
    let data: [JikanEpisode]
    let pagination: JikanPagination
}

struct JikanPagination: Decodable {
    let lastPage: Int

    enum CodingKeys: String, CodingKey {
        case lastPage = "last_visible_page"
    }
}

struct JikanEpisode: Decodable {
    let number: Int
    let title: String?
    let aired: String?

    enum CodingKeys: String, CodingKey {
        case number = "mal_id"
        case title, aired
    }

    func asDomain(
        provider: SearchProvider,
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
