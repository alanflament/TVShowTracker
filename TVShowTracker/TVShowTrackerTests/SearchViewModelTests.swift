//
//  SearchViewModelTests.swift
//  TVShowTrackerTests
//
//  Created by Alan Flament on 16/08/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

@MainActor
struct SearchViewModelTests {
    @Test func waitsForDebounceBeforeStartingSearch() async {
        let debounceGate = DebounceGate()
        let useCase = SearchCatalogUseCaseProbe(results: [catalog(title: "The Bear")])
        let viewModel = makeViewModel(useCase: useCase) { duration in
            try await debounceGate.wait(for: duration)
        }
        viewModel.query = "bear"

        let searchTask = Task { await viewModel.search() }
        while !(await debounceGate.isWaiting) {
            await Task.yield()
        }

        #expect(await debounceGate.duration == .milliseconds(300))
        #expect(await useCase.requests.isEmpty)
        #expect(viewModel.isSearching)

        await debounceGate.resume()
        await searchTask.value

        #expect(await useCase.requests == ["bear"])
    }

    @Test func keepsCurrentResultsVisibleWhileRefreshing() async {
        let firstCatalog = catalog(title: "The Bear")
        let refreshedCatalog = catalog(title: "Dark")
        let useCase = SearchCatalogUseCaseProbe(
            results: [firstCatalog, refreshedCatalog],
            suspendedRequestIndex: 1
        )
        let viewModel = makeViewModel(useCase: useCase)
        viewModel.query = "bear"
        await viewModel.search()

        viewModel.query = "dark"
        let refreshTask = Task { await viewModel.search() }
        while !(await useCase.isSuspended) {
            await Task.yield()
        }

        #expect(viewModel.isSearching)
        #expect(viewModel.isRefreshingResults)
        #expect(loadedCatalog(from: viewModel) == firstCatalog)

        await useCase.resume()
        await refreshTask.value

        #expect(!viewModel.isSearching)
        #expect(!viewModel.isRefreshingResults)
        #expect(loadedCatalog(from: viewModel) == refreshedCatalog)
    }

    private func makeViewModel(
        useCase: any SearchCatalogUseCase,
        debounce: @escaping @Sendable (Duration) async throws -> Void = { _ in }
    ) -> SearchViewModel {
        SearchViewModel(
            searchCatalogUseCase: useCase,
            followedMediaStore: FollowedMediaStore(repository: EmptyLibraryRepository()),
            debounce: debounce
        )
    }

    private func catalog(title: String) -> SearchCatalog {
        SearchCatalog(
            tvShows: [SearchCandidate(
                provider: .tmdb,
                providerID: title.hashValue,
                kind: .tvShow,
                title: title,
                alternateTitle: nil,
                posterURL: nil,
                releaseYear: nil,
                totalEpisodeCount: nil,
                status: nil,
                nextEpisodeNumber: nil,
                nextEpisodeAirDate: nil
            )],
            anime: [],
            unavailableProviders: [],
            providerErrors: [:]
        )
    }

    private func loadedCatalog(from viewModel: SearchViewModel) -> SearchCatalog? {
        guard case let .loaded(catalog) = viewModel.state else {
            return nil
        }
        return catalog
    }
}

private actor DebounceGate {
    private(set) var duration: Duration?
    private var continuation: CheckedContinuation<Void, Never>?

    var isWaiting: Bool {
        continuation != nil
    }

    func wait(for duration: Duration) async throws {
        self.duration = duration
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
        try Task.checkCancellation()
    }

    func resume() {
        continuation?.resume()
        continuation = nil
    }
}

private actor SearchCatalogUseCaseProbe: SearchCatalogUseCase {
    private let results: [SearchCatalog]
    private let suspendedRequestIndex: Int?
    private var continuation: CheckedContinuation<Void, Never>?
    private(set) var requests = [String]()

    init(results: [SearchCatalog], suspendedRequestIndex: Int? = nil) {
        self.results = results
        self.suspendedRequestIndex = suspendedRequestIndex
    }

    var isSuspended: Bool {
        continuation != nil
    }

    func search(matching query: String) async -> SearchCatalog {
        let requestIndex = requests.count
        requests.append(query)

        if requestIndex == suspendedRequestIndex {
            await withCheckedContinuation { continuation in
                self.continuation = continuation
            }
        }

        return results[requestIndex]
    }

    func resume() {
        continuation?.resume()
        continuation = nil
    }
}

@MainActor
private struct EmptyLibraryRepository: LibraryRepository {
    func loadItems() throws -> [LibraryItem] {
        []
    }

    func save(_: LibraryItem) throws {}
    func delete(id _: String) throws {}
}
