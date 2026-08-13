//
//  ShowDetailsViewModel.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import SwiftUI

@MainActor @Observable
final class ShowDetailsViewModel {
    enum State {
        case idle
        case loading
        case loaded(ShowDetails)
        case failed(String)
    }

    let candidate: SearchCandidate
    private(set) var state: State = .idle
    private let useCase: any ShowDetailsUseCase
    private let followedMediaStore: FollowedMediaStore

    init(
        candidate: SearchCandidate,
        useCase: any ShowDetailsUseCase,
        followedMediaStore: FollowedMediaStore
    ) {
        self.candidate = candidate
        self.useCase = useCase
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
            let details = try await useCase.fetchDetails(for: candidate)
            followedMediaStore.update(with: details, for: candidate)
            state = .loaded(details)
        } catch {
            state = .failed((error as? LocalizedError)?.errorDescription ?? "Details could not be loaded.")
        }
    }
}
