//
//  FollowedMediaIntegrationTests.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import SwiftData
import Testing
@testable import TVShowTracker

@MainActor
struct FollowedMediaIntegrationTests {
    @Test func followedMediaStateIsSharedThroughFeatureViewModels() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: LibraryItemModel.self,
            configurations: configuration
        )
        let store = FollowedMediaStore(
            repository: SwiftDataLibraryRepository(modelContext: container.mainContext)
        )
        let searchViewModel = SearchViewModel(
            searchCatalogUseCase: DefaultSearchCatalogUseCase(
                tvShowRepository: TVShowRepositoryStub(),
                animeRepository: AnimeRepositoryStub()
            ),
            followedMediaStore: store
        )
        let libraryViewModel = LibraryViewModel(followedMediaStore: store)
        let candidate = MediaCandidate.tvShow(id: 42, title: "The Bear")

        #expect(searchViewModel.trackingStatus(for: candidate) == nil)

        searchViewModel.addToPlan(candidate)

        #expect(searchViewModel.trackingStatus(for: candidate) == .planToWatch)
        #expect(libraryViewModel.items.map(\.id) == [candidate.id])
    }
}
