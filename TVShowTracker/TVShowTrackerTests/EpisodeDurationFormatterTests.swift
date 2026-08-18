//
//  EpisodeDurationFormatterTests.swift
//  TVShowTrackerTests
//
//  Created by Alan Flament on 18/08/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

struct EpisodeDurationFormatterTests {
    @Test(arguments: [0, -1])
    func ignoresInvalidDurations(minutes: Int) {
        #expect(EpisodeDurationFormatter.format(minutes: minutes) == nil)
    }

    @Test(arguments: [
        (1, "1 min"),
        (59, "59 min"),
        (60, "1 hr 0 min"),
        (65, "1 hr 5 min"),
        (120, "2 hr 0 min")
    ])
    func formatsWholeMinutes(minutes: Int, expected: String) {
        #expect(EpisodeDurationFormatter.format(minutes: minutes) == expected)
    }

    @MainActor @Test func parsesJikanHoursAndMinutesWhileIgnoringSeconds() throws {
        let data = Data(#"""
        {
          "mal_id": 1,
          "title": "An anime",
          "images": { "jpg": {} },
          "episodes": 12,
          "duration": "1 hr. 5 min. 30 sec. per ep.",
          "aired": {},
          "genres": []
        }
        """#.utf8)
        let anime = try JSONDecoder().decode(JikanDetailsAnime.self, from: data)
        let episodeData = Data(#"{ "mal_id": 1, "title": "Episode 1" }"#.utf8)
        let episode = try JSONDecoder().decode(JikanEpisode.self, from: episodeData)

        #expect(anime.episodeDurationMinutes == 65)
        #expect(episode.asDomain(
            provider: .jikan,
            showID: anime.id,
            runtimeMinutes: anime.episodeDurationMinutes
        ).runtimeMinutes == 65)
    }

    @MainActor @Test func mapsAniListDurationOntoEachEpisode() async throws {
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
        let candidate = SearchCandidate(
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

private struct EpisodeDurationHTTPClientStub: HTTPClient {
    let data: Data

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        guard let url = request.url,
              let response = HTTPURLResponse(
                  url: url,
                  statusCode: 200,
                  httpVersion: nil,
                  headerFields: nil
              )
        else {
            throw EpisodeDurationTestError.invalidRequest
        }
        return (data, response)
    }
}

private enum EpisodeDurationTestError: Error {
    case invalidRequest
}
