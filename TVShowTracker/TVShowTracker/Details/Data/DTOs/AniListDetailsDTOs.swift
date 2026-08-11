//
//  AniListDetailsDTOs.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

struct AniListDetailsGraphQLRequest: Encodable {
    let query: String
    let variables: [String: Int]
}

struct AniListDetailsResponse: Decodable {
    let data: AniListDetailsData?
    let errors: [AniListGraphQLError]?
}

struct AniListDetailsData: Decodable {
    let media: AniListDetailsAnime?

    enum CodingKeys: String, CodingKey {
        case media = "Media"
    }
}

struct AniListDetailsAnime: Decodable {
    let id: Int
    let title: AniListTitle
    let description: String?
    let coverImage: AniListCoverImage
    let status: String?
    let episodes: Int?
    let startDate: AniListFuzzyDate
    let genres: [String]
    let airingSchedule: AniListAiringSchedule?

    var asDomain: ShowDetails {
        ShowDetails(
            provider: .aniList,
            providerID: id,
            kind: .anime,
            title: title.preferredTitle,
            alternateTitle: title.alternateTitle,
            overview: description,
            posterURL: coverImage.large ?? coverImage.medium,
            backdropURL: nil,
            releaseYear: startDate.year,
            status: SearchMediaStatus(anilistStatus: status),
            totalEpisodeCount: episodes,
            genres: genres,
            seasonSummaries: episodes.map {
                [SeasonSummary(
                    provider: .aniList,
                    showID: id,
                    number: 1,
                    name: "Episodes",
                    episodeCount: $0,
                    airDate: nil
                )]
            } ?? []
        )
    }
}

struct AniListAiringSchedule: Decodable {
    let nodes: [AniListAiringNode]
}

struct AniListAiringNode: Decodable {
    let episode: Int
    let airingAt: Int
}
