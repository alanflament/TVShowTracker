//
//  AppContainer+DemoData.swift
//  TVShowTracker
//
//  Created by Alan Flament on 16/08/2026.
//

import Foundation

extension AppContainer {
    static var usesDemoData: Bool {
        #if DEBUG
            ProcessInfo.processInfo.arguments.contains("--demo-data")
        #else
            false
        #endif
    }

    static func seedDemoStateIfNeeded(
        _ followedMediaStore: FollowedMediaStore,
        _ episodeScheduleStore: EpisodeScheduleStore,
        _ episodeWatchStore: EpisodeWatchStore,
        _ episodeDetailsStore: EpisodeDetailsStore
    ) {
        guard usesDemoData else {
            return
        }

        seedDemoLibrary(into: followedMediaStore)
        seedDemoSchedules(
            followedMediaStore: followedMediaStore,
            episodeScheduleStore: episodeScheduleStore,
            episodeWatchStore: episodeWatchStore,
            episodeDetailsStore: episodeDetailsStore
        )
    }
}

private extension AppContainer {
    static func seedDemoLibrary(into store: FollowedMediaStore) {
        let samples: [(MediaCandidate, TrackingStatus)] = [
            (demoCandidate(id: 95396, title: "Severance", status: .airing), .watching),
            (demoCandidate(id: 1396, title: "Breaking Bad", status: .finished), .watching),
            (demoCandidate(id: 136_315, title: "The Bear", status: .airing), .paused),
            (demoCandidate(id: 70523, title: "Dark", status: .finished), .completed),
            (demoCandidate(id: 63247, title: "Westworld", status: .cancelled), .dropped)
        ]
        for sample in samples {
            if let existingItem = store.item(id: sample.0.id) {
                store.updateTrackingStatus(sample.1, for: existingItem)
            } else {
                store.addIfMissing(sample.0, trackingStatus: sample.1)
            }
        }
    }

    static func seedDemoSchedules(
        followedMediaStore: FollowedMediaStore,
        episodeScheduleStore: EpisodeScheduleStore,
        episodeWatchStore: EpisodeWatchStore,
        episodeDetailsStore: EpisodeDetailsStore
    ) {
        let episodesByProviderID = demoEpisodes(now: .now)

        for item in followedMediaStore.items {
            guard let episodes = episodesByProviderID[item.providerID] else {
                continue
            }
            episodeScheduleStore.save(item: item, seasons: [
                ShowSeason(
                    provider: item.provider,
                    showID: item.providerID,
                    number: 1,
                    name: "Season 1",
                    episodes: episodes
                )
            ])
            episodeWatchStore.markUnwatched(episodes)
            for episode in episodes {
                episodeDetailsStore.save(EpisodeDetails(
                    episode: episode,
                    voteAverage: 8.5
                ))
            }
        }
    }

    static func demoEpisodes(now: Date) -> [Int: [ShowEpisode]] {
        [
            1396: [demoEpisode(
                showID: 1396,
                number: 16,
                title: "Felina",
                airDate: now.addingTimeInterval(-86400),
                runtimeMinutes: 55
            )],
            95396: [
                demoEpisode(
                    showID: 95396,
                    number: 1,
                    title: "Hello, Ms. Cobel",
                    airDate: now.addingTimeInterval(-172_800),
                    runtimeMinutes: 65
                ),
                demoEpisode(
                    showID: 95396,
                    number: 2,
                    title: "Goodbye, Mrs. Selvig",
                    airDate: now.addingTimeInterval(-86400),
                    runtimeMinutes: 52
                ),
                demoEpisode(
                    showID: 95396,
                    number: 3,
                    title: "Who Is Alive?",
                    airDate: now.addingTimeInterval(604_800),
                    runtimeMinutes: 60
                )
            ]
        ]
    }

    static func demoEpisode(
        showID: Int,
        number: Int,
        title: String,
        airDate: Date,
        runtimeMinutes: Int? = nil
    ) -> ShowEpisode {
        ShowEpisode(
            provider: .tmdb,
            showID: showID,
            seasonNumber: 1,
            number: number,
            title: title,
            overview: nil,
            airDate: airDate,
            stillURL: nil,
            runtimeMinutes: runtimeMinutes
        )
    }

    static func demoCandidate(
        id: Int,
        title: String,
        status: MediaStatus
    ) -> MediaCandidate {
        MediaCandidate(
            provider: .tmdb,
            providerID: id,
            kind: .tvShow,
            title: title,
            alternateTitle: nil,
            posterURL: nil,
            releaseYear: 2022,
            totalEpisodeCount: 10,
            status: status,
            nextEpisodeNumber: nil,
            nextEpisodeAirDate: nil
        )
    }
}
