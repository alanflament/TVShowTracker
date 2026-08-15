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
    let format: String?
    let relations: AniListDetailsRelations?

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

struct AniListDetailsRelations: Decodable {
    let edges: [AniListDetailsRelation]
}

struct AniListDetailsRelation: Decodable {
    let relationType: String
    let node: AniListDetailsInstallment

    var connectsSeasons: Bool {
        ["PREQUEL", "SEQUEL"].contains(relationType) && node.isSeasonInstallment
    }
}

struct AniListDetailsInstallment: Decodable {
    let id: Int
    let title: AniListTitle
    let format: String?
    let status: String?
    let episodes: Int?
    let startDate: AniListFuzzyDate
    let relations: AniListDetailsRelations?

    var isSeasonInstallment: Bool {
        ["TV", "TV_SHORT", "ONA"].contains(format)
    }

    var installmentReference: AnimeInstallmentReference {
        AnimeInstallmentReference(
            providerID: id,
            title: title.preferredTitle,
            releaseYear: startDate.year,
            releaseMonth: startDate.month,
            releaseDay: startDate.day,
            episodeCount: episodes,
            status: SearchMediaStatus(anilistStatus: status)
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
