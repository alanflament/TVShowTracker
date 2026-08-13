//
//  CalendarCoordinator.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import SwiftUI

@MainActor
final class CalendarCoordinator {
    private let nextEpisodeUseCase: any NextEpisodeUseCase
    private let followedMediaStore: FollowedMediaStore
    private let episodeWatchStore: EpisodeWatchStore
    private let episodeScheduleStore: EpisodeScheduleStore
    private let followedMediaRefreshStore: FollowedMediaRefreshStore
    private let detailsCoordinator: DetailsCoordinator

    init(
        nextEpisodeUseCase: any NextEpisodeUseCase,
        followedMediaStore: FollowedMediaStore,
        episodeWatchStore: EpisodeWatchStore,
        episodeScheduleStore: EpisodeScheduleStore,
        followedMediaRefreshStore: FollowedMediaRefreshStore,
        detailsCoordinator: DetailsCoordinator
    ) {
        self.nextEpisodeUseCase = nextEpisodeUseCase
        self.followedMediaStore = followedMediaStore
        self.episodeWatchStore = episodeWatchStore
        self.episodeScheduleStore = episodeScheduleStore
        self.followedMediaRefreshStore = followedMediaRefreshStore
        self.detailsCoordinator = detailsCoordinator
    }

    func makeCalendarViewModel() -> CalendarViewModel {
        CalendarViewModel(
            nextEpisodeUseCase: nextEpisodeUseCase,
            followedMediaStore: followedMediaStore,
            episodeWatchStore: episodeWatchStore,
            episodeScheduleStore: episodeScheduleStore,
            followedMediaRefreshStore: followedMediaRefreshStore
        )
    }

    func makeDetailsView(for candidate: SearchCandidate) -> ShowDetailsView {
        detailsCoordinator.makeDetailsView(for: candidate)
    }

    func makeEpisodeDetailsView(
        for candidate: SearchCandidate,
        episode: ShowEpisode
    ) -> EpisodeDetailsView {
        detailsCoordinator.makeEpisodeDetailsView(for: candidate, episode: episode)
    }
}
