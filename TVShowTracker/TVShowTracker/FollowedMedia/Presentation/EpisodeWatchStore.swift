//
//  EpisodeWatchStore.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation
import Observation

@MainActor @Observable
final class EpisodeWatchStore {
    private let repository: any EpisodeWatchRepository

    private(set) var watchedEpisodeIDs = Set<String>()
    private(set) var errorMessage: String?

    init(repository: any EpisodeWatchRepository) {
        self.repository = repository
        reload()
    }

    func reload() {
        do {
            watchedEpisodeIDs = try Set(repository.loadWatchedEpisodes().map(\.id))
            errorMessage = nil
        } catch {
            watchedEpisodeIDs = []
            errorMessage = error.localizedDescription
        }
    }

    func isWatched(_ episode: ShowEpisode) -> Bool {
        watchedEpisodeIDs.contains(episode.id)
    }

    func toggle(_ episode: ShowEpisode) {
        if isWatched(episode) {
            markUnwatched(episode)
        } else {
            markWatched(episode)
        }
    }

    func markWatched(_ episode: ShowEpisode, watchedAt: Date?) {
        guard !isWatched(episode) else {
            return
        }

        saveWatchedEpisode(WatchedEpisode(episode: episode, watchedAt: watchedAt ?? .now))
    }

    private func markWatched(_ episode: ShowEpisode) {
        saveWatchedEpisode(WatchedEpisode(episode: episode))
    }

    private func saveWatchedEpisode(_ watchedEpisode: WatchedEpisode) {
        do {
            try repository.save(watchedEpisode)
            watchedEpisodeIDs.insert(watchedEpisode.id)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func markUnwatched(_ episode: ShowEpisode) {
        do {
            try repository.delete(id: episode.id)
            watchedEpisodeIDs.remove(episode.id)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
