//
//  SwiftDataEpisodeWatchRepository.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataEpisodeWatchRepository: EpisodeWatchRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadWatchedEpisodes() throws -> [WatchedEpisode] {
        let descriptor = FetchDescriptor<WatchedEpisodeModel>(
            sortBy: [SortDescriptor(\WatchedEpisodeModel.watchedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { $0.asDomain() }
    }

    func save(_ episode: WatchedEpisode) throws {
        let episodeID = episode.id
        let descriptor = FetchDescriptor<WatchedEpisodeModel>(
            predicate: #Predicate { $0.id == episodeID }
        )

        if try modelContext.fetch(descriptor).isEmpty {
            modelContext.insert(WatchedEpisodeModel(episode: episode))
            try modelContext.save()
        }
    }

    func delete(id: String) throws {
        let descriptor = FetchDescriptor<WatchedEpisodeModel>(
            predicate: #Predicate { $0.id == id }
        )
        if let episode = try modelContext.fetch(descriptor).first {
            modelContext.delete(episode)
            try modelContext.save()
        }
    }
}
