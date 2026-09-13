//
//  AniListGraphQLRequest.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

struct AniListGraphQLRequest<Variables: Encodable>: Encodable {
    let query: String
    let variables: Variables
}
