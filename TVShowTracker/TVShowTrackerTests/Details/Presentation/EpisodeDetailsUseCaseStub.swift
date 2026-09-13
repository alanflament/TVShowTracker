//
//  EpisodeDetailsUseCaseStub.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import SwiftData
import Testing
@testable import TVShowTracker

struct EpisodeDetailsUseCaseStub: ShowDetailsUseCase {
    let details: EpisodeDetails

    func fetchDetails(for _: MediaCandidate) async throws -> ShowDetails {
        throw EpisodeDetailsError.notFound
    }

    func fetchEpisodes(for _: MediaCandidate) async throws -> [ShowSeason] {
        []
    }

    func fetchEpisodeDetails(
        for _: MediaCandidate,
        episode _: ShowEpisode
    ) async throws -> EpisodeDetails {
        details
    }
}
