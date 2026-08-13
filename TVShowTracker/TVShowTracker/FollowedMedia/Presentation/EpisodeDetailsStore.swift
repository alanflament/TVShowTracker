//
//  EpisodeDetailsStore.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/08/2026.
//

import Foundation
import Observation

@MainActor @Observable
final class EpisodeDetailsStore {
    private let repository: any EpisodeDetailsRepository

    private(set) var detailsByID = [String: EpisodeDetails]()
    private(set) var errorMessage: String?

    init(repository: any EpisodeDetailsRepository) {
        self.repository = repository
        reload()
    }

    func details(for episode: ShowEpisode) -> EpisodeDetails? {
        detailsByID[episode.id]
    }

    func save(_ details: EpisodeDetails) {
        do {
            try repository.save(details)
            detailsByID[details.id] = details
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func reload() {
        do {
            detailsByID = try Dictionary(
                uniqueKeysWithValues: repository.loadEpisodeDetails().map { ($0.id, $0) }
            )
            errorMessage = nil
        } catch {
            detailsByID = [:]
            errorMessage = error.localizedDescription
        }
    }
}
