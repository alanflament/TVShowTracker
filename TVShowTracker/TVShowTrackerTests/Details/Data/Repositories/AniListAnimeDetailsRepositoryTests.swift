//
//  AniListAnimeDetailsRepositoryTests.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

@MainActor
struct AniListAnimeDetailsRepositoryTests {
    @Test func animeDetailsDecodesAniListMediaResponse() async throws {
        let data = Data(#"""
        {
          "data": {
            "Media": {
              "id": 20,
              "title": {
                "userPreferred": "NARUTO",
                "english": "Naruto",
                "romaji": "NARUTO",
                "native": "NARUTO -ナルト-"
              },
              "description": "A ninja story.",
              "coverImage": { "large": null, "medium": null },
              "format": "TV",
              "status": "FINISHED",
              "episodes": 220,
              "startDate": { "year": 2002 },
              "genres": ["Action"]
            }
          }
        }
        """#.utf8)
        let repository = AniListAnimeDetailsRepository(
            httpClient: HTTPClientStub(data: data, statusCode: 200)
        )

        let details = try await repository.fetchDetails(for: .anime(id: 20, title: "Naruto"))

        #expect(details.providerID == 20)
        #expect(details.title == "NARUTO")
        #expect(details.totalEpisodeCount == 220)
    }

    @Test func mapsAniListDurationOntoEachEpisode() async throws {
        let data = Data(#"""
        {
          "data": {
            "Media": {
              "id": 1,
              "title": { "userPreferred": "An anime" },
              "coverImage": {},
              "status": "RELEASING",
              "episodes": 2,
              "duration": 24,
              "startDate": {},
              "genres": [],
              "airingSchedule": { "nodes": [] }
            }
          }
        }
        """#.utf8)
        let repository = AniListAnimeDetailsRepository(
            httpClient: EpisodeDurationHTTPClientStub(data: data)
        )
        let candidate = MediaCandidate(
            provider: .aniList,
            providerID: 1,
            kind: .anime,
            title: "An anime",
            alternateTitle: nil,
            posterURL: nil,
            releaseYear: nil,
            totalEpisodeCount: 2,
            status: .airing,
            nextEpisodeNumber: nil,
            nextEpisodeAirDate: nil
        )

        let seasons = try await repository.fetchEpisodes(for: candidate)

        #expect(seasons.first?.episodes.map(\.runtimeMinutes) == [24, 24])
    }
}
