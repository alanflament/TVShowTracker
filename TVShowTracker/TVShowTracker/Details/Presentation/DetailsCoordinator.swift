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

    init(
        useCase: any ShowDetailsUseCase,
        followedMediaStore: FollowedMediaStore,
        episodeWatchStore: EpisodeWatchStore
    ) {
        self.useCase = useCase
        self.followedMediaStore = followedMediaStore
        self.episodeWatchStore = episodeWatchStore
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
                    episodeWatchStore: self.episodeWatchStore
                )
            }
        )
    }
}
