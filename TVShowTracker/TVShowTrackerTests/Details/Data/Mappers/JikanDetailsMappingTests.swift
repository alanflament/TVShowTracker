//
//  JikanDetailsMappingTests.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

@MainActor
struct JikanDetailsMappingTests {
    @Test func parsesJikanHoursAndMinutesWhileIgnoringSeconds() throws {
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
}
