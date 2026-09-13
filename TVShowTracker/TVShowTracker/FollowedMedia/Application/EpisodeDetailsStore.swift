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
    private let episodeDetailsRepository: any EpisodeDetailsRepository

    private(set) var detailsByID = [String: EpisodeDetails]()
    private(set) var errorMessage: String?

    init(episodeDetailsRepository: any EpisodeDetailsRepository) {
        self.episodeDetailsRepository = episodeDetailsRepository
        reload()
    }

    func details(for episode: ShowEpisode) -> EpisodeDetails? {
        detailsByID[episode.id]
    }

    func save(_ details: EpisodeDetails) {
        do {
            try episodeDetailsRepository.save(details)
            detailsByID[details.id] = details
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func reload() {
        do {
            detailsByID = try Dictionary(
                uniqueKeysWithValues: episodeDetailsRepository.loadEpisodeDetails().map { ($0.id, $0) }
            )
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
