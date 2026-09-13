//
//  ConcurrentDetailsUseCase.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

struct ConcurrentDetailsUseCase: ShowDetailsUseCase {
    let probe: RefreshConcurrencyProbe

    func fetchDetails(for candidate: MediaCandidate) async throws -> ShowDetails {
        ShowDetails(
            provider: candidate.provider,
            providerID: candidate.providerID,
            kind: candidate.kind,
            title: candidate.title,
            alternateTitle: nil,
            overview: nil,
            posterURL: nil,
            backdropURL: nil,
            releaseYear: nil,
            status: .airing,
            totalEpisodeCount: nil,
            genres: [],
            seasonSummaries: []
        )
    }

    func fetchEpisodes(for _: MediaCandidate) async throws -> [ShowSeason] {
        await probe.beginRequest()
        try? await Task.sleep(nanoseconds: 20_000_000)
        await probe.finishRequest()
        return []
    }
}
