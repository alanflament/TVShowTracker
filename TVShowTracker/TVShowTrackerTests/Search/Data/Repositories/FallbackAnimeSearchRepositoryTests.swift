//
//  FallbackAnimeSearchRepositoryTests.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

@MainActor
struct FallbackAnimeSearchRepositoryTests {
    @Test func animeFallbackUsesJikanWhenAniListFails() async throws {
        let repository = FallbackAnimeSearchRepository(
            primary: FailingAnimeRepository(),
            fallback: AnimeRepositoryStub(candidates: [.jikanAnime(id: 1, title: "Frieren")])
        )

        let candidates = try await repository.searchAnime(matching: "frieren")

        #expect(candidates.map(\.title) == ["Frieren"])
        #expect(candidates.map(\.provider) == [.jikan])
    }
}
