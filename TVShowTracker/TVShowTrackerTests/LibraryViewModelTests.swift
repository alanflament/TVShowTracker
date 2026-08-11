//
//  LibraryViewModelTests.swift
//  TVShowTrackerTests
//
//  Created by Alan Flament on 11/08/2026.
//

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
}

private func candidate(id: Int, title: String) -> SearchCandidate {
    SearchCandidate(
        provider: .tmdb,
        providerID: id,
        kind: .tvShow,
        title: title,
        alternateTitle: nil,
        posterURL: nil,
        releaseYear: nil,
        totalEpisodeCount: nil,
        status: nil,
        nextEpisodeNumber: nil,
        nextEpisodeAirDate: nil
    )
}
