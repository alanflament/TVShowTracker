//
//  JikanAPIClient.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

struct JikanAPIClient: Sendable {
    let httpClient: any HTTPClient

    func get<Response: Decodable>(
        path: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> Response {
        try await httpClient.get(
            baseURL: "https://api.jikan.moe",
            path: path,
            queryItems: queryItems
        )
    }
}
