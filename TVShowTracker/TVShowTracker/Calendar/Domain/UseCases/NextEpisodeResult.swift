//
//  NextEpisodeResult.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

struct NextEpisodeResult: Sendable {
    let episodes: [CalendarEpisode]
    let missingScheduleCount: Int
}
