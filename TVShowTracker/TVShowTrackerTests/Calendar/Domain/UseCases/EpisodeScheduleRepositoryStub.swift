//
//  EpisodeScheduleRepositoryStub.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

struct EpisodeScheduleRepositoryStub: EpisodeScheduleRepository {
    let schedules: [EpisodeSchedule]

    func loadSchedules() throws -> [EpisodeSchedule] {
        schedules
    }

    func save(_: EpisodeSchedule) throws {}

    func delete(id _: String) throws {}
}
