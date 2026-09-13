//
//  BackupImportDetailsUseCaseStub.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import SwiftData
import Testing
@testable import TVShowTracker

struct BackupImportDetailsUseCaseStub: ShowDetailsUseCase {
    let posterURL: URL?
    let shouldFail: Bool

    init(posterURL: URL? = nil, shouldFail: Bool = false) {
        self.posterURL = posterURL
        self.shouldFail = shouldFail
    }

    func fetchDetails(for candidate: MediaCandidate) async throws -> ShowDetails {
        if shouldFail {
            throw BackupImportTestError.expectedFailure
        }
        return ShowDetails(
            provider: candidate.provider,
            providerID: candidate.providerID,
            kind: candidate.kind,
            title: candidate.title,
            alternateTitle: candidate.alternateTitle,
            overview: nil,
            posterURL: posterURL,
            backdropURL: nil,
            releaseYear: candidate.releaseYear,
            status: candidate.status,
            totalEpisodeCount: candidate.totalEpisodeCount,
            genres: [],
            seasonSummaries: []
        )
    }

    func fetchEpisodes(for candidate: MediaCandidate) async throws -> [ShowSeason] {
        if shouldFail {
            throw BackupImportTestError.expectedFailure
        }
        return [ShowSeason(
            provider: candidate.provider,
            showID: candidate.providerID,
            number: 1,
            name: "Season 1",
            episodes: []
        )]
    }
}
