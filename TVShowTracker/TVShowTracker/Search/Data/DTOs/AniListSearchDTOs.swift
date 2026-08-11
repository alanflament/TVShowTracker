//
//  AniListSearchDTOs.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

struct AniListSearchRequest: Encodable {
    let query: String
    let variables: [String: String]
}

struct AniListSearchResponse: Decodable {
    let data: AniListData?
    let errors: [AniListGraphQLError]?
}
