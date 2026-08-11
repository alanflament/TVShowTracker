//
//  UnconfiguredTVShowDetailsRepository.swift
//  TVShowTracker
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
