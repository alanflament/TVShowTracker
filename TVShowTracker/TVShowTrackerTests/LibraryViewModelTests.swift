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

    @Test func filtersItemsByPersistedReleaseStatus() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: LibraryItemModel.self,
            configurations: configuration
        )
        let store = FollowedMediaStore(
            repository: SwiftDataLibraryRepository(modelContext: container.mainContext)
        )
        store.toggle(candidate(id: 1, title: "Airing", status: .airing))
        store.toggle(candidate(id: 2, title: "Upcoming", status: .upcoming))
        store.toggle(candidate(id: 3, title: "Finished", status: .finished))
        let viewModel = LibraryViewModel(followedMediaStore: store)

        viewModel.filter = .watching
        #expect(viewModel.items.map(\.title) == ["Airing"])

        viewModel.filter = .upcoming
        #expect(viewModel.items.map(\.title) == ["Upcoming"])

        viewModel.filter = .finished
        #expect(viewModel.items.map(\.title) == ["Finished"])
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
