//
//  EpisodeScheduleRefreshUseCase.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

protocol EpisodeScheduleRefreshUseCase: Sendable {
    func refreshSchedules(for items: [LibraryItem]) async -> [EpisodeScheduleRefreshResult]
}
