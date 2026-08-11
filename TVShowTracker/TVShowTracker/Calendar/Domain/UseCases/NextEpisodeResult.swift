//
//  NextEpisodeResult.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

struct NextEpisodeResult: Sendable {
    let episode: CalendarEpisode?
    let missingScheduleCount: Int
}
