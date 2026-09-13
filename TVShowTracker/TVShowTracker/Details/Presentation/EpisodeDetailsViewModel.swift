//
//  EpisodeDetailsViewModel.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/08/2026.
//

import Foundation
import Observation

@MainActor @Observable
final class EpisodeDetailsViewModel {
    enum State {
        case idle
        case loading
        case loaded(EpisodeDetails)
        case failed(String)
    }

    let candidate: MediaCandidate
    let episode: ShowEpisode
    private(set) var state: State = .idle

    private let showDetailsUseCase: any ShowDetailsUseCase
    private let episodeDetailsStore: EpisodeDetailsStore
    private let episodeWatchStore: EpisodeWatchStore

    init(
        candidate: MediaCandidate,
        episode: ShowEpisode,
        showDetailsUseCase: any ShowDetailsUseCase,
        episodeDetailsStore: EpisodeDetailsStore,
        episodeWatchStore: EpisodeWatchStore
    ) {
        self.candidate = candidate
        self.episode = episode
        self.showDetailsUseCase = showDetailsUseCase
        self.episodeDetailsStore = episodeDetailsStore
        self.episodeWatchStore = episodeWatchStore
    }

    func load() async {
        guard case .idle = state else {
            return
        }

        if let cachedDetails = episodeDetailsStore.details(for: episode) {
            state = .loaded(cachedDetails)
        } else {
            state = .loading
        }

        do {
            let details = try await showDetailsUseCase.fetchEpisodeDetails(for: candidate, episode: episode)
            try Task.checkCancellation()
            episodeDetailsStore.save(details)
            state = .loaded(details)
        } catch {
            if Task.isCancelled || error is CancellationError {
                if let cachedDetails = episodeDetailsStore.details(for: episode) {
                    state = .loaded(cachedDetails)
                } else {
                    state = .idle
                }
                return
            }
            guard episodeDetailsStore.details(for: episode) == nil else {
                return
            }
            state = .failed(
                (error as? LocalizedError)?.errorDescription ?? "Episode details could not be loaded."
            )
        }
    }

    var isWatched: Bool {
        episodeWatchStore.isWatched(episode)
    }

    func toggleWatched() {
        guard episode.isReleased else {
            return
        }
        episodeWatchStore.toggle(episode)
    }
}
