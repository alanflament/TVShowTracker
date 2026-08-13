//
//  DetailsCoordinator.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import SwiftUI

@MainActor
final class DetailsCoordinator {
    private let useCase: any ShowDetailsUseCase
    private let followedMediaStore: FollowedMediaStore
    private let episodeWatchStore: EpisodeWatchStore
    private let episodeScheduleStore: EpisodeScheduleStore
    private let episodeDetailsStore: EpisodeDetailsStore

    init(
        useCase: any ShowDetailsUseCase,
        followedMediaStore: FollowedMediaStore,
        episodeWatchStore: EpisodeWatchStore,
        episodeScheduleStore: EpisodeScheduleStore,
        episodeDetailsStore: EpisodeDetailsStore
    ) {
        self.useCase = useCase
        self.followedMediaStore = followedMediaStore
        self.episodeWatchStore = episodeWatchStore
        self.episodeScheduleStore = episodeScheduleStore
        self.episodeDetailsStore = episodeDetailsStore
    }

    func makeDetailsSheet(for candidate: SearchCandidate) -> DetailsSheetView {
        DetailsSheetView(detailsView: makeDetailsView(for: candidate))
    }

    func makeDetailsView(for candidate: SearchCandidate) -> ShowDetailsView {
        ShowDetailsView(
            viewModel: ShowDetailsViewModel(
                candidate: candidate,
                useCase: useCase,
                followedMediaStore: followedMediaStore
            ),
            makeEpisodesViewModel: {
                EpisodesViewModel(
                    candidate: candidate,
                    useCase: self.useCase,
                    followedMediaStore: self.followedMediaStore,
                    episodeScheduleStore: self.episodeScheduleStore,
                    episodeWatchStore: self.episodeWatchStore
                )
            },
            makeEpisodeDetailsView: { episode in
                self.makeEpisodeDetailsView(for: candidate, episode: episode)
            }
        )
    }

    func makeEpisodeDetailsView(
        for candidate: SearchCandidate,
        episode: ShowEpisode
    ) -> EpisodeDetailsView {
        EpisodeDetailsView(
            viewModel: EpisodeDetailsViewModel(
                candidate: candidate,
                episode: episode,
                useCase: useCase,
                episodeDetailsStore: episodeDetailsStore,
                episodeWatchStore: episodeWatchStore
            )
        )
    }
}
