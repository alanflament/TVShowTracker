//
//  SearchViewModel.swift
//  TVShowTracker
//
//  Created by Alan Flament on 30/07/2026.
//

import SwiftUI

@MainActor @Observable
final class SearchViewModel {
    enum State {
        case idle
        case loading
        case loaded(SearchCatalog)
    }

    var query = ""
    private(set) var state: State = .idle

    private let searchCatalogUseCase: any SearchCatalogUseCase
    private let followedMediaStore: FollowedMediaStore

    init(
        searchCatalogUseCase: any SearchCatalogUseCase,
        followedMediaStore: FollowedMediaStore
    ) {
        self.searchCatalogUseCase = searchCatalogUseCase
        self.followedMediaStore = followedMediaStore
    }

    func trackingStatus(for candidate: SearchCandidate) -> TrackingStatus? {
        followedMediaStore.item(id: candidate.id)?.trackingStatus
    }

    func add(_ candidate: SearchCandidate, trackingStatus: TrackingStatus) {
        followedMediaStore.addIfMissing(candidate, trackingStatus: trackingStatus)
    }

    func update(_ candidate: SearchCandidate, trackingStatus: TrackingStatus) {
        guard let item = followedMediaStore.item(id: candidate.id) else {
            add(candidate, trackingStatus: trackingStatus)
            return
        }
        followedMediaStore.updateTrackingStatus(trackingStatus, for: item)
    }

    func remove(_ candidate: SearchCandidate) {
        guard let item = followedMediaStore.item(id: candidate.id) else {
            return
        }
        followedMediaStore.remove(item)
    }

    func search() async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedQuery.count >= 2 else {
            state = .idle
            return
        }

        state = .loading

        do {
            try await Task.sleep(nanoseconds: 300_000_000)
        } catch {
            return
        }

        guard !Task.isCancelled else {
            return
        }

        let catalog = await searchCatalogUseCase.search(matching: trimmedQuery)

        guard !Task.isCancelled else {
            return
        }

        state = .loaded(catalog)
    }
}
