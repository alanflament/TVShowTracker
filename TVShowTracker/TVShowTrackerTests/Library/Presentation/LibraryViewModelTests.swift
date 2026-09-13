//
//  LibraryViewModelTests.swift
//  TVShowTrackerTests
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation
import SwiftData
import Testing
@testable import TVShowTracker

@MainActor
struct LibraryViewModelTests {
    @Test func sortsAndFiltersPersistedItemsLocally() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: LibraryItemModel.self,
            configurations: configuration
        )
        let store = FollowedMediaStore(
            repository: SwiftDataLibraryRepository(modelContext: container.mainContext)
        )
        let candidates = [
            candidate(id: 1, title: "Zeta"),
            candidate(id: 2, title: "Éclair"),
            candidate(id: 3, title: "Alpha")
        ]
        candidates.forEach(store.toggle)
        let viewModel = LibraryViewModel(followedMediaStore: store)

        #expect(viewModel.items.map(\.title) == ["Alpha", "Éclair", "Zeta"])

        viewModel.query = "eclair"

        #expect(viewModel.items.map(\.title) == ["Éclair"])
    }

    @Test func filtersItemsByPersonalTrackingStatus() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: LibraryItemModel.self,
            configurations: configuration
        )
        let store = FollowedMediaStore(
            repository: SwiftDataLibraryRepository(modelContext: container.mainContext)
        )
        store.addIfMissing(candidate(id: 1, title: "Airing", status: .airing), trackingStatus: .watching)
        store.addIfMissing(candidate(id: 2, title: "Upcoming", status: .upcoming), trackingStatus: .planToWatch)
        store.addIfMissing(candidate(id: 3, title: "Finished", status: .finished), trackingStatus: .completed)
        let viewModel = LibraryViewModel(followedMediaStore: store)

        viewModel.category = .active
        viewModel.filter = .watching
        #expect(viewModel.items.map(\.title) == ["Airing"])

        viewModel.category = .planned
        #expect(viewModel.items.map(\.title) == ["Upcoming"])

        viewModel.category = .history
        viewModel.filter = .completed
        #expect(viewModel.items.map(\.title) == ["Finished"])

        #expect(viewModel.count(for: LibraryCategory.all) == 3)
        #expect(viewModel.count(for: .history) == 1)
        #expect(viewModel.count(for: LibraryFilter.completed) == 1)
        #expect(viewModel.count(for: LibraryFilter.dropped) == 0)
    }

    @Test func changingPrimaryCategoryResetsSecondaryFilter() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: LibraryItemModel.self,
            configurations: configuration
        )
        let store = FollowedMediaStore(
            repository: SwiftDataLibraryRepository(modelContext: container.mainContext)
        )
        let viewModel = LibraryViewModel(followedMediaStore: store)
        viewModel.category = .active
        viewModel.filter = .paused

        viewModel.category = .history

        #expect(viewModel.filter == .all)
    }

    @Test func resetsSearchAndTrackingStatusFilters() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: LibraryItemModel.self,
            configurations: configuration
        )
        let store = FollowedMediaStore(
            repository: SwiftDataLibraryRepository(modelContext: container.mainContext)
        )
        store.addIfMissing(candidate(id: 1, title: "The Bear"), trackingStatus: .watching)
        let viewModel = LibraryViewModel(followedMediaStore: store)
        viewModel.query = "missing"
        viewModel.category = .history
        viewModel.filter = .completed

        viewModel.resetFilters()

        #expect(viewModel.query.isEmpty)
        #expect(viewModel.category == .all)
        #expect(viewModel.filter == .all)
        #expect(viewModel.items.map(\.title) == ["The Bear"])
    }

    @Test func preparesAFilteredSearchForDiscoverWithoutLosingItsQuery() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: LibraryItemModel.self,
            configurations: configuration
        )
        let store = FollowedMediaStore(
            repository: SwiftDataLibraryRepository(modelContext: container.mainContext)
        )
        store.addIfMissing(candidate(id: 1, title: "The Bear"), trackingStatus: .watching)
        let viewModel = LibraryViewModel(followedMediaStore: store)
        viewModel.query = "  Severance  "
        viewModel.category = .history
        viewModel.filter = .completed

        viewModel.prepareForDiscoverSearch()

        #expect(viewModel.discoverQuery == "Severance")
        #expect(viewModel.query == "  Severance  ")
        #expect(viewModel.category == .all)
        #expect(viewModel.filter == .all)
    }

    @Test func newlyFollowedSearchResultAppearsInTheStillFilteredLibrary() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: LibraryItemModel.self,
            configurations: configuration
        )
        let store = FollowedMediaStore(
            repository: SwiftDataLibraryRepository(modelContext: container.mainContext)
        )
        store.addIfMissing(candidate(id: 1, title: "The Bear"), trackingStatus: .watching)
        let viewModel = LibraryViewModel(followedMediaStore: store)
        viewModel.query = "Severance"

        #expect(viewModel.items.isEmpty)

        store.addIfMissing(candidate(id: 2, title: "Severance"), trackingStatus: .planToWatch)

        #expect(viewModel.items.map(\.title) == ["Severance"])
    }
}

private func candidate(
    id: Int,
    title: String,
    status: MediaStatus? = nil,
    posterURL: URL? = nil
) -> MediaCandidate {
    MediaCandidate(
        provider: .tmdb,
        providerID: id,
        kind: .tvShow,
        title: title,
        alternateTitle: nil,
        posterURL: posterURL,
        releaseYear: nil,
        totalEpisodeCount: nil,
        status: status,
        nextEpisodeNumber: nil,
        nextEpisodeAirDate: nil
    )
}
