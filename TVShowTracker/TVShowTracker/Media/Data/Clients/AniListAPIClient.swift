//
//  AniListAPIClient.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

struct AniListAPIClient: Sendable {
    let httpClient: any HTTPClient

    func query<Variables: Encodable, Payload: Decodable>(
        _ document: String,
        variables: Variables
    ) async throws -> Payload {
        guard let url = URL(string: "https://graphql.anilist.co") else {
            throw HTTPClientError.invalidRequest
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(AniListGraphQLRequest(query: document, variables: variables))

        let (data, response) = try await httpClient.data(for: request)
        let decoder = JSONDecoder()
        // GraphQL can return a useful error on either a successful or failed HTTP status.
        if let failure = try? decoder.decode(AniListGraphQLErrorResponse.self, from: data),
           let message = failure.errors?.first?.message {
            throw AniListAPIError.queryFailed(message)
        }
        try response.validateSuccessfulStatusCode()
        let result = try decoder.decode(AniListGraphQLResponse<Payload>.self, from: data)
        guard let payload = result.data else {
            throw AniListAPIError.queryFailed("No data was returned.")
        }
        return payload
    }
}
