//
//  ShowDetailsUseCaseStub.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import SwiftData
import Testing
@testable import TVShowTracker

struct ShowDetailsUseCaseStub: ShowDetailsUseCase {
    let episode: ShowEpisode
    let shouldFail: Bool

    func fetchDetails(for _: MediaCandidate) async throws -> ShowDetails {
        throw TVTimeImportTestError.expectedFailure
    }

    func fetchEpisodes(for _: MediaCandidate) async throws -> [ShowSeason] {
        if shouldFail {
            throw TVTimeImportTestError.expectedFailure
        }
        return [ShowSeason(
            provider: episode.provider,
            showID: episode.showID,
            number: episode.seasonNumber,
            name: "Season \(episode.seasonNumber)",
            episodes: [episode]
        )]
    }
}
