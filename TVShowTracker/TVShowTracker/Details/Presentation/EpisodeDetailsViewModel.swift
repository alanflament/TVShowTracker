//
//  EpisodeDetailsViewModel.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/08/2026.
//

import Foundation

@MainActor @Observable
final class EpisodeDetailsViewModel {
    enum State {
        case idle
        case loading
        case loaded(EpisodeDetails)
        case failed(String)
    }

    let candidate: SearchCandidate
    let episode: ShowEpisode
    private(set) var state: State = .idle

    private let useCase: any ShowDetailsUseCase
    private let episodeDetailsStore: EpisodeDetailsStore
    private let episodeWatchStore: EpisodeWatchStore

    init(
        candidate: SearchCandidate,
        episode: ShowEpisode,
        useCase: any ShowDetailsUseCase,
        episodeDetailsStore: EpisodeDetailsStore,
        episodeWatchStore: EpisodeWatchStore
    ) {
        self.candidate = candidate
        self.episode = episode
        self.useCase = useCase
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
            let details = try await useCase.fetchEpisodeDetails(for: candidate, episode: episode)
            episodeDetailsStore.save(details)
            state = .loaded(details)
        } catch {
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
