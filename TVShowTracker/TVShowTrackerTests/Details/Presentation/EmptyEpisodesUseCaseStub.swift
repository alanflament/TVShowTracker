//
//  EmptyEpisodesUseCaseStub.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import SwiftData
import Testing
@testable import TVShowTracker

struct EmptyEpisodesUseCaseStub: ShowDetailsUseCase {
    func fetchDetails(for _: MediaCandidate) async throws -> ShowDetails {
        throw EpisodeDetailsError.notFound
    }

    func fetchEpisodes(for _: MediaCandidate) async throws -> [ShowSeason] {
        []
    }
}
