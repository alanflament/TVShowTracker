//
//  FailingAnimeRepository.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

struct FailingAnimeRepository: AnimeSearchRepository {
    func searchAnime(matching _: String) async throws -> [MediaCandidate] {
        throw SearchRepositoryTestError.expectedFailure
    }
}
