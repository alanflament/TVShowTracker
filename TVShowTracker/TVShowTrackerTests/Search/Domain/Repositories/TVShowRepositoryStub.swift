//
//  TVShowRepositoryStub.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

struct TVShowRepositoryStub: TVShowSearchRepository {
    let candidates: [MediaCandidate]

    init(candidates: [MediaCandidate] = []) {
        self.candidates = candidates
    }

    func searchTVShows(matching _: String) async throws -> [MediaCandidate] {
        candidates
    }
}
