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
