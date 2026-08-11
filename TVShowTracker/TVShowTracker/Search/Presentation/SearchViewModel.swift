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

    func isFollowed(_ candidate: SearchCandidate) -> Bool {
        followedMediaStore.contains(candidate)
    }

    func toggleFollowed(_ candidate: SearchCandidate) {
        followedMediaStore.toggle(candidate)
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
