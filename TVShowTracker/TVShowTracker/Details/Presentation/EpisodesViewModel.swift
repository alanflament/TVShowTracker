//
//  EpisodesViewModel.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import SwiftUI

@MainActor @Observable
final class EpisodesViewModel {
    enum State {
        case idle
        case loading
        case loaded([ShowSeason])
        case failed(String)
    }

    let candidate: SearchCandidate
    private(set) var state: State = .idle
    private let useCase: any ShowDetailsUseCase

    init(candidate: SearchCandidate, useCase: any ShowDetailsUseCase) {
        self.candidate = candidate
        self.useCase = useCase
    }

    func load() async {
        guard case .idle = state else {
            return
        }

        state = .loading
        do {
            state = try .loaded(await useCase.fetchEpisodes(for: candidate))
        } catch {
            state = .failed((error as? LocalizedError)?.errorDescription ?? "Episodes could not be loaded.")
        }
    }
}
