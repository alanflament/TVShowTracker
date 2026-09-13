//
//  TMDBAPIClientTests.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

@MainActor
struct TMDBAPIClientTests {
    @Test func combinesEndpointQueryWithAuthenticationAndLanguage() async throws {
        let httpClient = HTTPClientStub(data: Data("[]".utf8), statusCode: 200)
        let client = TMDBAPIClient(accessToken: "test-token", language: "fr-FR", httpClient: httpClient)

        let _: [Int] = try await client.get(
            path: "/3/search/tv",
            queryItems: [URLQueryItem(name: "query", value: "A & B")]
        )

        let request = try #require(await httpClient.requests.first)
        let url = try #require(request.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.host == "api.themoviedb.org")
        #expect(components.path == "/3/search/tv")
        #expect(components.queryItems?.contains(URLQueryItem(name: "query", value: "A & B")) == true)
        #expect(components.queryItems?.contains(URLQueryItem(name: "language", value: "fr-FR")) == true)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-token")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }
}
