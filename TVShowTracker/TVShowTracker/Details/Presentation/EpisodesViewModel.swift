//
//  EpisodesViewModel.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation
import Observation

@MainActor @Observable
final class EpisodesViewModel {
    enum State {
        case idle
        case loading
        case loaded([ShowSeason])
        case failed(String)
    }

    let candidate: MediaCandidate
    private(set) var state: State = .idle
    private let showDetailsUseCase: any ShowDetailsUseCase
    private let followedMediaStore: FollowedMediaStore
    private let episodeScheduleStore: EpisodeScheduleStore
    private let episodeWatchStore: EpisodeWatchStore

    init(
        candidate: MediaCandidate,
        showDetailsUseCase: any ShowDetailsUseCase,
        followedMediaStore: FollowedMediaStore,
        episodeScheduleStore: EpisodeScheduleStore,
        episodeWatchStore: EpisodeWatchStore
    ) {
        self.candidate = candidate
        self.showDetailsUseCase = showDetailsUseCase
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
            let seasons = try await showDetailsUseCase.fetchEpisodes(for: candidate)
            try Task.checkCancellation()
            if let item = followedMediaStore.item(id: candidate.id) {
                episodeScheduleStore.save(item: item, seasons: seasons)
            }
            state = .loaded(seasons)
        } catch {
            if Task.isCancelled || error is CancellationError {
                state = .idle
                return
            }
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
        if !isWatched(episode) {
            addToWatchingIfNeeded()
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
        let releasedEpisodes = episodes.filter(\.isReleased)
        guard !releasedEpisodes.isEmpty else {
            return
        }
        addToWatchingIfNeeded()
        episodeWatchStore.markWatched(releasedEpisodes)
    }

    private func addToWatchingIfNeeded() {
        guard followedMediaStore.item(id: candidate.id) == nil else {
            return
        }

        followedMediaStore.addIfMissing(candidate, trackingStatus: .watching)
        guard let item = followedMediaStore.item(id: candidate.id),
              case let .loaded(seasons) = state
        else {
            return
        }
        episodeScheduleStore.save(item: item, seasons: seasons)
    }
}
