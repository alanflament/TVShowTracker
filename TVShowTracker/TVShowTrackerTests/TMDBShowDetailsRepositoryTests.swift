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
    @Test func refreshSnapshotReusesDetailsAndBoundsSeasonRequests() async throws {
        let client = TMDBHTTPClientProbe()
        let repository = TMDBShowDetailsRepository(
            accessToken: "token",
            language: "en-US",
            httpClient: client
        )
        let candidate = SearchCandidate(
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
}

private actor TMDBHTTPClientProbe: HTTPClient {
    private(set) var detailsRequestCount = 0
    private(set) var peakConcurrentSeasonRequests = 0
    private var activeSeasonRequests = 0

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let url = try #require(request.url)
        let data: Data

        if url.path == "/3/tv/42" {
            detailsRequestCount += 1
            data = Data(Self.detailsJSON.utf8)
        } else {
            activeSeasonRequests += 1
            peakConcurrentSeasonRequests = max(peakConcurrentSeasonRequests, activeSeasonRequests)
            try await Task.sleep(nanoseconds: 10_000_000)
            activeSeasonRequests -= 1
            let seasonNumber = Int(url.lastPathComponent) ?? 0
            data = Data(Self.seasonJSON(number: seasonNumber).utf8)
        }

        let response = try #require(HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        ))
        return (data, response)
    }

    private static let detailsJSON = """
    {
      "id": 42,
      "name": "Show",
      "original_name": "Show",
      "overview": "Overview",
      "poster_path": null,
      "backdrop_path": null,
      "first_air_date": "2020-01-01",
      "status": "Returning Series",
      "number_of_episodes": 5,
      "genres": [],
      "seasons": [
        { "id": 1, "name": "Season 1", "season_number": 1, "episode_count": 1, "air_date": "2020-01-01" },
        { "id": 2, "name": "Season 2", "season_number": 2, "episode_count": 1, "air_date": "2021-01-01" },
        { "id": 3, "name": "Season 3", "season_number": 3, "episode_count": 1, "air_date": "2022-01-01" },
        { "id": 4, "name": "Season 4", "season_number": 4, "episode_count": 1, "air_date": "2023-01-01" },
        { "id": 5, "name": "Season 5", "season_number": 5, "episode_count": 1, "air_date": "2024-01-01" }
      ]
    }
    """

    private static func seasonJSON(number: Int) -> String {
        """
        {
          "season_number": \(number),
          "name": "Season \(number)",
          "episodes": []
        }
        """
    }
}
