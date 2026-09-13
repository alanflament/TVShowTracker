//
//  JikanAnimeDetailsRepositoryTests.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

@MainActor
struct JikanAnimeDetailsRepositoryTests {
    @Test func decodesEpisodePaginationAtTheResponseRoot() async throws {
        let httpClient = PaginatedJikanHTTPClient()
        let repository = JikanAnimeDetailsRepository(httpClient: httpClient)

        let seasons = try await repository.fetchEpisodes(for: .jikanAnime(id: 1, title: "Anime"))

        #expect(seasons.count == 1)
        #expect(seasons.first?.episodes.map(\.number) == [1, 2])
        #expect(seasons.first?.episodes.map(\.runtimeMinutes) == [24, 24])
        #expect(await httpClient.requestedPages == [1, 2])
    }
}

private actor PaginatedJikanHTTPClient: HTTPClient {
    private(set) var requestedPages = [Int]()

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let url = try #require(request.url)
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        let body: String
        if url.path.hasSuffix("/full") {
            body = #"""
            {"data":{"mal_id":1,"title":"Anime","images":{"jpg":{}},"duration":"24 min per ep","aired":{},"genres":[]}}
            """#
        } else {
            let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
            let page = try #require(components.queryItems?.first(where: { $0.name == "page" })?.value.flatMap(Int.init))
            requestedPages.append(page)
            body = """
            {"data":[{"mal_id":\(page),"title":"Episode \(page)","aired":"2020-01-01T00:00:00+00:00"}],"pagination":{"last_visible_page":2}}
            """
        }
        let response = try #require(HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil))
        return (Data(body.utf8), response)
    }
}
