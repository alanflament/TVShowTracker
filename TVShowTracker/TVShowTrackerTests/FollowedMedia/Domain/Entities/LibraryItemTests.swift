//
//  LibraryItemTests.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

@MainActor
struct LibraryItemTests {
    @Test func animeInstallmentsKeepTheirOwnProviderNamespace() {
        let candidate = MediaCandidate(
            provider: .jikan, providerID: 100, kind: .anime, title: "Anime",
            alternateTitle: nil, posterURL: nil, releaseYear: nil,
            totalEpisodeCount: nil, status: .airing,
            nextEpisodeNumber: nil, nextEpisodeAirDate: nil,
            animeInstallments: [AnimeInstallmentReference(
                providerID: 200, title: "Season 1", releaseYear: nil,
                releaseMonth: nil, releaseDay: nil, episodeCount: 12, status: .airing
            )]
        )
        let saved = LibraryItem(candidate: candidate)
        #expect(saved.contains(episode(provider: .aniList, showID: 200)))
        #expect(!saved.contains(episode(provider: .jikan, showID: 200)))
        #expect(!saved.contains(episode(provider: .aniList, showID: 100)))
    }

    private func episode(provider: MediaProvider, showID: Int) -> ShowEpisode {
        ShowEpisode(
            provider: provider, showID: showID, seasonNumber: 1, number: 1,
            title: "Episode 1", overview: nil, airDate: nil, stillURL: nil, runtimeMinutes: nil
        )
    }
}
