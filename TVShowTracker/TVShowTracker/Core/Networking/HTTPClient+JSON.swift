//
//  HTTPClient+JSON.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

extension HTTPClient {
    func get<Response: Decodable>(
        baseURL: String,
        path: String,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:]
    ) async throws -> Response {
        var components = URLComponents(string: baseURL)
        components?.path = path
        components?.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let url = components?.url else {
            throw HTTPClientError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        for (name, value) in headers {
            request.setValue(value, forHTTPHeaderField: name)
        }
        let (data, response) = try await data(for: request)
        try response.validateSuccessfulStatusCode()
        return try JSONDecoder().decode(Response.self, from: data)
    }
}
