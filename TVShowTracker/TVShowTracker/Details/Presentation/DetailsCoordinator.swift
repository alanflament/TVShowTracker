//
//  DetailsCoordinator.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

@MainActor
final class DetailsCoordinator {
    private let showDetailsUseCase: any ShowDetailsUseCase
    private let followedMediaStore: FollowedMediaStore
    private let episodeWatchStore: EpisodeWatchStore
    private let episodeScheduleStore: EpisodeScheduleStore
    private let episodeDetailsStore: EpisodeDetailsStore

    init(
        showDetailsUseCase: any ShowDetailsUseCase,
        followedMediaStore: FollowedMediaStore,
        episodeWatchStore: EpisodeWatchStore,
        episodeScheduleStore: EpisodeScheduleStore,
        episodeDetailsStore: EpisodeDetailsStore
    ) {
        self.showDetailsUseCase = showDetailsUseCase
        self.followedMediaStore = followedMediaStore
        self.episodeWatchStore = episodeWatchStore
        self.episodeScheduleStore = episodeScheduleStore
        self.episodeDetailsStore = episodeDetailsStore
    }

    func makeDetailsSheet(for candidate: MediaCandidate) -> DetailsSheetView {
        DetailsSheetView(detailsView: makeDetailsView(for: candidate))
    }

    func makeDetailsView(for candidate: MediaCandidate) -> ShowDetailsView {
        ShowDetailsView(
            viewModel: ShowDetailsViewModel(
                candidate: candidate,
                showDetailsUseCase: showDetailsUseCase,
                followedMediaStore: followedMediaStore
            ),
            makeEpisodesView: { self.makeEpisodesView(for: candidate) }
        )
    }

    func makeEpisodesView(for candidate: MediaCandidate) -> EpisodesView {
        EpisodesView(
            viewModel: EpisodesViewModel(
                candidate: candidate,
                showDetailsUseCase: showDetailsUseCase,
                followedMediaStore: followedMediaStore,
                episodeScheduleStore: episodeScheduleStore,
                episodeWatchStore: episodeWatchStore
            ),
            makeEpisodeDetailsView: { episode in
                self.makeEpisodeDetailsView(for: candidate, episode: episode)
            }
        )
    }

    func makeEpisodeDetailsView(
        for candidate: MediaCandidate,
        episode: ShowEpisode,
        onShowMediaDetails: (() -> Void)? = nil
    ) -> EpisodeDetailsView {
        EpisodeDetailsView(
            viewModel: EpisodeDetailsViewModel(
                candidate: candidate,
                episode: episode,
                showDetailsUseCase: showDetailsUseCase,
                episodeDetailsStore: episodeDetailsStore,
                episodeWatchStore: episodeWatchStore
            ),
            onShowMediaDetails: onShowMediaDetails
        )
    }
}
