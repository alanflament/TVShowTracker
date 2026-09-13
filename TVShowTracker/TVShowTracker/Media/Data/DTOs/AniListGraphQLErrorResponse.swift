//
//  AniListGraphQLErrorResponse.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

struct AniListGraphQLErrorResponse: Decodable {
    let errors: [AniListGraphQLError]?
}
