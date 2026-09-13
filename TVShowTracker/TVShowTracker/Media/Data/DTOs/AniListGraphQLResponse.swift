//
//  AniListGraphQLResponse.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

struct AniListGraphQLResponse<Payload: Decodable>: Decodable {
    let data: Payload?
    let errors: [AniListGraphQLError]?
}
