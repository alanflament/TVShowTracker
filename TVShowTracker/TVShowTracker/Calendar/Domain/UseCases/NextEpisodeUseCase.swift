//
//  NextEpisodeUseCase.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

@MainActor
protocol NextEpisodeUseCase: Sendable {
    func findNextEpisode(
        in items: [LibraryItem],
        watchedEpisodeIDs: Set<String>,
        now: Date
    ) async -> NextEpisodeResult
}
