//
//  AnimeRepositoryStub.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

struct AnimeRepositoryStub: AnimeSearchRepository {
    let candidates: [MediaCandidate]

    init(candidates: [MediaCandidate] = []) {
        self.candidates = candidates
    }

    func searchAnime(matching _: String) async throws -> [MediaCandidate] {
        candidates
    }
}
