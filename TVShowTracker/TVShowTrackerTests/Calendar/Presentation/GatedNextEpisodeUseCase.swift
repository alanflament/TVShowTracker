//
//  GatedNextEpisodeUseCase.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

@MainActor
final class GatedNextEpisodeUseCase: NextEpisodeUseCase {
    private var results: [NextEpisodeResult]
    private var shouldSuspend = false
    private var continuation: CheckedContinuation<Void, Never>?
    private(set) var isSuspended = false

    init(results: [NextEpisodeResult]) {
        self.results = results
    }

    func suspendNextRequest() {
        shouldSuspend = true
    }

    func resume() {
        continuation?.resume()
        continuation = nil
    }

    func findNextEpisode(
        in _: [LibraryItem],
        watchedEpisodeIDs _: Set<String>,
        now _: Date
    ) async -> NextEpisodeResult {
        let result = results.removeFirst()
        if shouldSuspend {
            shouldSuspend = false
            isSuspended = true
            await withCheckedContinuation { continuation in
                self.continuation = continuation
            }
            isSuspended = false
        }
        return result
    }
}
