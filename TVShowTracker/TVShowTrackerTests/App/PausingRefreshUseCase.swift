//
//  PausingRefreshUseCase.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Observation
import SwiftData
import Testing
@testable import TVShowTracker

struct PausingRefreshUseCase: EpisodeScheduleRefreshUseCase {
    let gate: RefreshGate

    func refreshSchedules(
        for items: [LibraryItem],
        onResult: @escaping @Sendable (EpisodeScheduleRefreshResult) async -> Void
    ) async -> [EpisodeScheduleRefreshResult] {
        var results = [EpisodeScheduleRefreshResult]()
        for (index, item) in items.enumerated() {
            let result = EpisodeScheduleRefreshResult(item: item, seasons: [], status: nil)
            results.append(result)
            await onResult(result)
            if index == 0 {
                await gate.pause()
            }
        }
        return results
    }
}
