//
//  SearchRepositoryStubs.swift
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

struct AnimeRepositoryStub: AnimeSearchRepository {
    let candidates: [MediaCandidate]

    init(candidates: [MediaCandidate] = []) {
        self.candidates = candidates
    }

    func searchAnime(matching _: String) async throws -> [MediaCandidate] {
        candidates
    }
}

struct FailingTVShowRepository: TVShowSearchRepository {
    func searchTVShows(matching _: String) async throws -> [MediaCandidate] {
        throw TestError.expectedFailure
    }
}

struct FailingAnimeRepository: AnimeSearchRepository {
    func searchAnime(matching _: String) async throws -> [MediaCandidate] {
        throw TestError.expectedFailure
    }
}

private enum TestError: Error {
    case expectedFailure
}
