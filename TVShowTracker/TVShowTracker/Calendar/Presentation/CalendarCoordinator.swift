//
//  CalendarCoordinator.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

@MainActor
final class CalendarCoordinator {
    let viewModel: CalendarViewModel
    private let detailsCoordinator: DetailsCoordinator

    init(
        nextEpisodeUseCase: any NextEpisodeUseCase,
        followedMediaStore: FollowedMediaStore,
        episodeWatchStore: EpisodeWatchStore,
        episodeScheduleStore: EpisodeScheduleStore,
        followedMediaRefreshStore: FollowedMediaRefreshStore,
        detailsCoordinator: DetailsCoordinator
    ) {
        viewModel = CalendarViewModel(
            nextEpisodeUseCase: nextEpisodeUseCase,
            followedMediaStore: followedMediaStore,
            episodeWatchStore: episodeWatchStore,
            episodeScheduleStore: episodeScheduleStore,
            followedMediaRefreshStore: followedMediaRefreshStore
        )
        self.detailsCoordinator = detailsCoordinator
    }

    func makeDetailsView(for candidate: MediaCandidate) -> ShowDetailsView {
        detailsCoordinator.makeDetailsView(for: candidate)
    }

    func makeEpisodeDetailsView(
        for candidate: MediaCandidate,
        episode: ShowEpisode,
        onShowMediaDetails: @escaping () -> Void
    ) -> EpisodeDetailsView {
        detailsCoordinator.makeEpisodeDetailsView(
            for: candidate,
            episode: episode,
            onShowMediaDetails: onShowMediaDetails
        )
    }
}
