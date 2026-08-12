//
//  NextEpisodeResult.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

struct NextEpisodeResult: Sendable {
    let episodes: [CalendarEpisode]
    let availableEpisodeCount: Int
    let undatedMedia: [CalendarUndatedMedia]
}
