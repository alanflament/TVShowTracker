//
//  ShowDetailsViewModel.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation
import Observation

@MainActor @Observable
final class ShowDetailsViewModel {
    enum State {
        case idle
        case loading
        case loaded(ShowDetails)
        case failed(String)
    }

    let candidate: MediaCandidate
    private(set) var state: State = .idle
    private let showDetailsUseCase: any ShowDetailsUseCase
    private let followedMediaStore: FollowedMediaStore

    init(
        candidate: MediaCandidate,
        showDetailsUseCase: any ShowDetailsUseCase,
        followedMediaStore: FollowedMediaStore
    ) {
        self.candidate = candidate
        self.showDetailsUseCase = showDetailsUseCase
        self.followedMediaStore = followedMediaStore
    }

    var isFollowed: Bool {
        followedMediaStore.contains(candidate)
    }

    var trackingStatus: TrackingStatus? {
        followedMediaStore.item(id: candidate.id)?.trackingStatus
    }

    func setTrackingStatus(_ trackingStatus: TrackingStatus) {
        if let item = followedMediaStore.item(id: candidate.id) {
            followedMediaStore.updateTrackingStatus(trackingStatus, for: item)
        } else {
            followedMediaStore.addIfMissing(candidate, trackingStatus: trackingStatus)
        }

        guard followedMediaStore.contains(candidate),
              case let .loaded(details) = state
        else {
            return
        }
        followedMediaStore.update(with: details, for: candidate)
    }

    func removeFromLibrary() {
        guard let item = followedMediaStore.item(id: candidate.id) else {
            return
        }
        followedMediaStore.remove(item)
    }

    func load() async {
        guard case .idle = state else {
            return
        }

        state = .loading
        do {
            let details = try await showDetailsUseCase.fetchDetails(for: candidate)
            try Task.checkCancellation()
            followedMediaStore.update(with: details, for: candidate)
            state = .loaded(details)
        } catch {
            if Task.isCancelled || error is CancellationError {
                state = .idle
                return
            }
            state = .failed((error as? LocalizedError)?.errorDescription ?? "Details could not be loaded.")
        }
    }
}
