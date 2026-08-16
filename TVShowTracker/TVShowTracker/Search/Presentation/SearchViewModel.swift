//
//  SearchViewModel.swift
//  TVShowTracker
//
//  Created by Alan Flament on 30/07/2026.
//

import SwiftUI

@MainActor @Observable
final class SearchViewModel {
    static let searchDebounceDuration = Duration.milliseconds(300)

    enum State {
        case idle
        case loading
        case loaded(SearchCatalog)
    }

    var query = ""
    private(set) var state: State = .idle
    private(set) var isSearching = false

    var isRefreshingResults: Bool {
        guard isSearching, case let .loaded(catalog) = state else {
            return false
        }
        return !catalog.isEmpty
    }

    private let searchCatalogUseCase: any SearchCatalogUseCase
    private let followedMediaStore: FollowedMediaStore
    private let debounce: @Sendable (Duration) async throws -> Void
    private var activeSearchID: UUID?

    init(
        searchCatalogUseCase: any SearchCatalogUseCase,
        followedMediaStore: FollowedMediaStore,
        debounce: @escaping @Sendable (Duration) async throws -> Void = { duration in
            try await Task.sleep(for: duration)
        }
    ) {
        self.searchCatalogUseCase = searchCatalogUseCase
        self.followedMediaStore = followedMediaStore
        self.debounce = debounce
    }

    func trackingStatus(for candidate: SearchCandidate) -> TrackingStatus? {
        followedMediaStore.item(id: candidate.id)?.trackingStatus
    }

    func add(_ candidate: SearchCandidate, trackingStatus: TrackingStatus) {
        followedMediaStore.addIfMissing(candidate, trackingStatus: trackingStatus)
    }

    func addToPlan(_ candidate: SearchCandidate) {
        add(candidate, trackingStatus: .planToWatch)
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
            activeSearchID = nil
            isSearching = false
            state = .idle
            return
        }

        let searchID = UUID()
        activeSearchID = searchID
        isSearching = true

        if !isDisplayingResults {
            state = .loading
        }

        do {
            try await debounce(Self.searchDebounceDuration)
        } catch {
            finishSearch(id: searchID)
            return
        }

        guard !Task.isCancelled, normalizedQuery == trimmedQuery else {
            finishSearch(id: searchID)
            return
        }

        let catalog = await searchCatalogUseCase.search(matching: trimmedQuery)

        guard !Task.isCancelled, normalizedQuery == trimmedQuery else {
            finishSearch(id: searchID)
            return
        }

        state = .loaded(catalog)
        finishSearch(id: searchID)
    }

    private var normalizedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isDisplayingResults: Bool {
        guard case let .loaded(catalog) = state else {
            return false
        }
        return !catalog.isEmpty
    }

    private func finishSearch(id: UUID) {
        guard activeSearchID == id else {
            return
        }
        activeSearchID = nil
        isSearching = false
    }
}
