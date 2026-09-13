//
//  CalendarRefreshUseCaseStub.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

struct CalendarRefreshUseCaseStub: EpisodeScheduleRefreshUseCase {
    func refreshSchedules(
        for _: [LibraryItem],
        onResult _: @escaping @Sendable (EpisodeScheduleRefreshResult) async -> Void
    ) async -> [EpisodeScheduleRefreshResult] {
        []
    }
}
