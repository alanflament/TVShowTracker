//
//  EpisodeScheduleRepository.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

@MainActor
protocol EpisodeScheduleRepository {
    func loadSchedules() throws -> [EpisodeSchedule]
    func save(_ schedule: EpisodeSchedule) throws
    func delete(id: String) throws
}
