//
//  TMDBShowDetailsRepositoryTests.swift
//  TVShowTrackerTests
//
//  Created by Alan Flament on 16/08/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

@MainActor
struct TMDBShowDetailsRepositoryTests {
    @Test func seasonMappingExcludesUndatedPlaceholderEpisodes() throws {
        let data = Data(Self.seasonWithPlaceholderJSON.utf8)
        let details = try JSONDecoder().decode(TMDBSeasonDetails.self, from: data)

        let season = details.asDomain(provider: .tmdb, showID: 111_110)

        #expect(season.episodes.map(\.number) == [1])
        #expect(season.episodes.first?.title == "Confirmed episode")
    }

    @Test func refreshSnapshotReusesDetailsAndBoundsSeasonRequests() async throws {
        let client = TMDBHTTPClientProbe()
        let repository = TMDBShowDetailsRepository(
            accessToken: "token",
            language: "en-US",
            httpClient: client
        )
        let candidate = MediaCandidate(
            provider: .tmdb,
            providerID: 42,
            kind: .tvShow,
            title: "Show",
            alternateTitle: nil,
            posterURL: nil,
            releaseYear: nil,
            totalEpisodeCount: nil,
            status: .airing,
            nextEpisodeNumber: nil,
            nextEpisodeAirDate: nil
        )

        let snapshot = try await repository.fetchRefreshSnapshot(for: candidate)

        #expect(snapshot.seasons?.count == 5)
        #expect(await client.detailsRequestCount == 1)
        #expect(await client.peakConcurrentSeasonRequests <= 3)
    }

    @Test func cancelledSeasonRequestAbortsRefreshSnapshot() async {
        let repository = TMDBShowDetailsRepository(
            accessToken: "test-token",
            language: "en-US",
            httpClient: TMDBHTTPClientProbe(cancelsSeasonRequests: true)
        )
        do {
            _ = try await repository.fetchRefreshSnapshot(for: .tvShow(id: 42, title: "Show"))
            Issue.record("Cancellation must not become a successful partial snapshot")
        } catch is CancellationError {
            // Expected: the refresh caller must receive cancellation.
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    private static let seasonWithPlaceholderJSON = """
    {
      "season_number": 3,
      "name": "Season 3",
      "episodes": [
        {
          "episode_number": 1,
          "name": "Confirmed episode",
          "overview": "",
          "air_date": "2026-09-01",
          "still_path": null,
          "runtime": null,
          "vote_average": 0
        },
        {
          "episode_number": 2,
          "name": "Placeholder episode",
          "overview": "",
          "air_date": null,
          "still_path": null,
          "runtime": null,
          "vote_average": 0
        }
      ]
    }
    """
}
