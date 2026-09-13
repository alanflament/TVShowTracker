//
//  EpisodeScheduleReading.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

@MainActor
protocol EpisodeScheduleReading {
    func schedule(for item: LibraryItem) -> EpisodeSchedule?
}
