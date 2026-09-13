//
//  TMDBAPIClient.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

struct TMDBAPIClient: Sendable {
    let accessToken: String
    let language: String
    let httpClient: any HTTPClient

    func get<Response: Decodable>(
        path: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> Response {
        try await httpClient.get(
            baseURL: "https://api.themoviedb.org",
            path: path,
            queryItems: queryItems + [URLQueryItem(name: "language", value: language)],
            headers: ["Authorization": "Bearer \(accessToken)"]
        )
    }
}
