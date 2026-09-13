//
//  FailingTVShowRepository.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

struct FailingTVShowRepository: TVShowSearchRepository {
    func searchTVShows(matching _: String) async throws -> [MediaCandidate] {
        throw SearchRepositoryTestError.expectedFailure
    }
}
