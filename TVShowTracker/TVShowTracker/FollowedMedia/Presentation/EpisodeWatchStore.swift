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
    private let followedMediaStore: FollowedMediaStore?
    private let episodeScheduleStore: EpisodeScheduleStore?

    private(set) var watchedEpisodeIDs = Set<String>()
    private(set) var errorMessage: String?

    init(
        repository: any EpisodeWatchRepository,
        followedMediaStore: FollowedMediaStore? = nil,
        episodeScheduleStore: EpisodeScheduleStore? = nil
    ) {
        self.repository = repository
        self.followedMediaStore = followedMediaStore
        self.episodeScheduleStore = episodeScheduleStore
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

        if saveWatchedEpisode(WatchedEpisode(episode: episode, watchedAt: watchedAt ?? .now)) {
            synchronizeTrackingStatus(for: episode)
        }
    }

    func markWatched(_ episodes: [ShowEpisode]) {
        let episodesToMark = episodes.filter { !isWatched($0) }
        guard !episodesToMark.isEmpty else {
            return
        }

        let watchedAt = Date.now
        let watchedEpisodes = episodesToMark.map {
            WatchedEpisode(episode: $0, watchedAt: watchedAt)
        }

        do {
            try repository.save(watchedEpisodes)
            watchedEpisodeIDs.formUnion(watchedEpisodes.map(\.id))
            errorMessage = nil
            episodesToMark.forEach(synchronizeTrackingStatus)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func markWatched(_ episode: ShowEpisode) {
        if saveWatchedEpisode(WatchedEpisode(episode: episode)) {
            synchronizeTrackingStatus(for: episode)
        }
    }

    @discardableResult
    private func saveWatchedEpisode(_ watchedEpisode: WatchedEpisode) -> Bool {
        do {
            try repository.save(watchedEpisode)
            watchedEpisodeIDs.insert(watchedEpisode.id)
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func markUnwatched(_ episode: ShowEpisode) {
        do {
            try repository.delete(id: episode.id)
            watchedEpisodeIDs.remove(episode.id)
            errorMessage = nil
            synchronizeTrackingStatus(for: episode)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func synchronizeTrackingStatus(for episode: ShowEpisode) {
        guard let followedMediaStore,
              let item = followedMediaStore.items.first(where: { $0.contains(episode) })
        else {
            return
        }

        let releasedEpisodes = episodeScheduleStore?
            .schedule(for: item)?
            .seasons
            .filter { !$0.isSpecial }
            .flatMap(\.episodes)
            .filter(\.isReleased) ?? []

        let trackingStatus: TrackingStatus
        if !releasedEpisodes.isEmpty, releasedEpisodes.allSatisfy(isWatched) {
            trackingStatus = .completed
        } else {
            trackingStatus = .watching
        }
        followedMediaStore.updateTrackingStatus(trackingStatus, for: item)
    }
}
