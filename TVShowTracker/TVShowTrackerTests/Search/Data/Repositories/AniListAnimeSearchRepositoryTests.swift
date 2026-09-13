//
//  AniListAnimeSearchRepositoryTests.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

@MainActor
struct AniListAnimeSearchRepositoryTests {
    @Test func animeSearchGroupsSequelChainIntoSeasons() async throws {
        let repository = AniListAnimeSearchRepository(
            httpClient: HTTPClientStub(data: .dandadanAniListSearchResponse, statusCode: 200)
        )

        let candidates = try await repository.searchAnime(matching: "Dandadan")

        #expect(candidates.count == 1)
        #expect(candidates.first?.title == "Dandadan")
        #expect(candidates.first?.totalEpisodeCount == 24)
        #expect(candidates.first?.animeInstallments.map(\.providerID) == [171_018, 185_660, 198_966])
    }
}
