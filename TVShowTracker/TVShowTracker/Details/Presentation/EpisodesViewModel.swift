//
//  EpisodesViewModel.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import SwiftUI

@MainActor @Observable
final class EpisodesViewModel {
    enum State {
        case idle
        case loading
        case loaded([ShowSeason])
        case failed(String)
    }

    let candidate: SearchCandidate
    private(set) var state: State = .idle
    private let useCase: any ShowDetailsUseCase
    private let followedMediaStore: FollowedMediaStore
    private let episodeScheduleStore: EpisodeScheduleStore
    private let episodeWatchStore: EpisodeWatchStore

    init(
        candidate: SearchCandidate,
        useCase: any ShowDetailsUseCase,
        followedMediaStore: FollowedMediaStore,
        episodeScheduleStore: EpisodeScheduleStore,
        episodeWatchStore: EpisodeWatchStore
    ) {
        self.candidate = candidate
        self.useCase = useCase
        self.followedMediaStore = followedMediaStore
        self.episodeScheduleStore = episodeScheduleStore
        self.episodeWatchStore = episodeWatchStore
    }

    func load() async {
        guard case .idle = state else {
            return
        }

        state = .loading
        do {
            let seasons = try await useCase.fetchEpisodes(for: candidate)
            if let item = followedMediaStore.item(id: candidate.id) {
                episodeScheduleStore.save(item: item, seasons: seasons)
            }
            state = .loaded(seasons)
        } catch {
            state = .failed((error as? LocalizedError)?.errorDescription ?? "Episodes could not be loaded.")
        }
    }

    func isWatched(_ episode: ShowEpisode) -> Bool {
        episodeWatchStore.isWatched(episode)
    }

    func toggleWatched(_ episode: ShowEpisode) {
        guard episode.isReleased else {
            return
        }
        episodeWatchStore.toggle(episode)
    }

    func toggleSeasonWatched(_ season: ShowSeason) {
        if areAllWatched(in: season.episodes) {
            episodeWatchStore.markUnwatched(season.episodes)
        } else {
            markWatched(season.episodes)
        }
    }

    func markAllWatched(_ seasons: [ShowSeason]) {
        markWatched(seasons.flatMap(\.episodes))
    }

    func releasedUnwatchedEpisodeCount(in episodes: [ShowEpisode]) -> Int {
        episodes.count { $0.isReleased && !isWatched($0) }
    }

    func watchedEpisodeCount(in episodes: [ShowEpisode]) -> Int {
        episodes.count { isWatched($0) }
    }

    func areAllWatched(in episodes: [ShowEpisode]) -> Bool {
        !episodes.isEmpty && episodes.allSatisfy(isWatched)
    }

    private func markWatched(_ episodes: [ShowEpisode]) {
        episodeWatchStore.markWatched(episodes.filter(\.isReleased))
    }
}
