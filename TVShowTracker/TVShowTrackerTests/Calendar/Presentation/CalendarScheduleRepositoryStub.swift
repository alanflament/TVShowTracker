//
//  CalendarScheduleRepositoryStub.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

@MainActor
struct CalendarScheduleRepositoryStub: EpisodeScheduleRepository {
    func loadSchedules() throws -> [EpisodeSchedule] {
        []
    }

    func save(_: EpisodeSchedule) throws {}
    func delete(id _: String) throws {}
}
