//
//  DetailsCoordinator.swift
//  TVShowTracker
//

import SwiftUI

@MainActor
final class DetailsCoordinator {
    private let useCase: any ShowDetailsUseCase

    init(useCase: any ShowDetailsUseCase) {
        self.useCase = useCase
    }

    func makeDetailsView(for candidate: SearchCandidate) -> ShowDetailsView {
        ShowDetailsView(
            viewModel: ShowDetailsViewModel(candidate: candidate, useCase: useCase),
            makeEpisodesViewModel: {
                EpisodesViewModel(candidate: candidate, useCase: self.useCase)
            }
        )
    }
}
