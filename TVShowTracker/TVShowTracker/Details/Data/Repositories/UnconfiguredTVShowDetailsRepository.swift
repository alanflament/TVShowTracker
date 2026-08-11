//
//  UnconfiguredTVShowDetailsRepository.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

struct UnconfiguredTVShowDetailsRepository: TVShowDetailsRepository {
    func fetchDetails(for _: SearchCandidate) async throws -> ShowDetails {
        throw SearchConfigurationError.missingTMDBAccessToken
    }

    func fetchEpisodes(for _: SearchCandidate) async throws -> [ShowSeason] {
        throw SearchConfigurationError.missingTMDBAccessToken
    }
}
