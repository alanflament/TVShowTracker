//
//  ScheduleRefreshUseCaseStub.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

struct ScheduleRefreshUseCaseStub: EpisodeScheduleRefreshUseCase {
    let result: EpisodeScheduleRefreshResult

    func refreshSchedules(
        for _: [LibraryItem],
        onResult: @escaping @Sendable (EpisodeScheduleRefreshResult) async -> Void
    ) async -> [EpisodeScheduleRefreshResult] {
        await onResult(result)
        return [result]
    }
}
