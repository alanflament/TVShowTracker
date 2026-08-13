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

        viewModel.filter = .watching
        #expect(viewModel.items.map(\.title) == ["Airing"])

        viewModel.filter = .planToWatch
        #expect(viewModel.items.map(\.title) == ["Upcoming"])

        viewModel.filter = .completed
        #expect(viewModel.items.map(\.title) == ["Finished"])

        #expect(viewModel.count(for: .all) == 3)
        #expect(viewModel.count(for: .watching) == 1)
        #expect(viewModel.count(for: .paused) == 0)
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
        viewModel.filter = .completed

        viewModel.resetFilters()

        #expect(viewModel.query.isEmpty)
        #expect(viewModel.filter == .all)
        #expect(viewModel.items.map(\.title) == ["The Bear"])
    }

    @Test func preservesTrackingStatusWhenProviderDetailsAreUpdated() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: LibraryItemModel.self,
            configurations: configuration
        )
        let store = FollowedMediaStore(
            repository: SwiftDataLibraryRepository(modelContext: container.mainContext)
        )
        let searchCandidate = candidate(id: 1, title: "Dark", status: .finished)
        store.addIfMissing(searchCandidate, trackingStatus: .watching)

        store.update(with: details(for: searchCandidate, totalEpisodeCount: 26), for: searchCandidate)

        #expect(store.items.first?.trackingStatus == .watching)
        #expect(store.items.first?.status == .airing)
    }

    @Test func legacyLibraryItemDefaultsToWatching() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: LibraryItemModel.self,
            configurations: configuration
        )
        let model = try LibraryItemModel(
            id: "tmdb:42",
            providerRawValue: SearchProvider.tmdb.rawValue,
            providerID: 42,
            kindRawValue: SearchMediaKind.tvShow.rawValue,
            title: "The Bear",
            alternateTitle: nil,
            posterURLString: nil,
            releaseYear: nil,
            totalEpisodeCount: nil,
            statusRawValue: SearchMediaStatus.finished.rawValue,
            nextEpisodeNumber: nil,
            nextEpisodeAirDate: nil,
            animeInstallmentsData: JSONEncoder().encode([AnimeInstallmentReference]()),
            addedAt: .now
        )
        container.mainContext.insert(model)
        try container.mainContext.save()

        let items = try SwiftDataLibraryRepository(modelContext: container.mainContext).loadItems()

        #expect(items.first?.trackingStatus == .watching)
    }

    @Test func preservesPosterURLWhenReloadingPersistedItems() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: LibraryItemModel.self,
            configurations: configuration
        )
        let store = FollowedMediaStore(
            repository: SwiftDataLibraryRepository(modelContext: container.mainContext)
        )
        let posterURL = try #require(URL(string: "https://image.tmdb.org/t/p/w342/poster.jpg"))
        store.toggle(candidate(id: 1, title: "Breaking Bad", posterURL: posterURL))

        store.reload()

        #expect(store.items.first?.posterURL == posterURL)
    }

    @Test func enrichesFollowedMediaWithLoadedDetails() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: LibraryItemModel.self,
            configurations: configuration
        )
        let store = FollowedMediaStore(
            repository: SwiftDataLibraryRepository(modelContext: container.mainContext)
        )
        let searchCandidate = candidate(id: 1, title: "Mushoku Tensei")
        store.toggle(searchCandidate)

        store.update(
            with: details(for: searchCandidate, totalEpisodeCount: 62),
            for: searchCandidate
        )

        #expect(store.items.first?.totalEpisodeCount == 62)
        #expect(store.items.first?.status == .airing)
    }
}

private func candidate(
    id: Int,
    title: String,
    status: SearchMediaStatus? = nil,
    posterURL: URL? = nil
) -> SearchCandidate {
    SearchCandidate(
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

private func details(for candidate: SearchCandidate, totalEpisodeCount: Int) -> ShowDetails {
    ShowDetails(
        provider: candidate.provider,
        providerID: candidate.providerID,
        kind: candidate.kind,
        title: candidate.title,
        alternateTitle: candidate.alternateTitle,
        overview: nil,
        posterURL: candidate.posterURL,
        backdropURL: nil,
        releaseYear: candidate.releaseYear,
        status: .airing,
        totalEpisodeCount: totalEpisodeCount,
        genres: [],
        seasonSummaries: []
    )
}
