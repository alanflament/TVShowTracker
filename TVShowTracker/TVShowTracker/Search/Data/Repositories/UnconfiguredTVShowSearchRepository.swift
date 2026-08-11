//
//  UnconfiguredTVShowSearchRepository.swift
//  TVShowTracker
//
//  Created by Alan Flament on 30/07/2026.
//

struct UnconfiguredTVShowSearchRepository: TVShowSearchRepository {
    func searchTVShows(matching _: String) async throws -> [SearchCandidate] {
        throw SearchConfigurationError.missingTMDBAccessToken
    }
}

enum SearchConfigurationError: Error, Sendable {
    case missingTMDBAccessToken
}
