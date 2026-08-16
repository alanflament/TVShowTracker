//
//  MainCoordinatorTests.swift
//  TVShowTrackerTests
//
//  Created by Alan Flament on 16/08/2026.
//

import Testing
@testable import TVShowTracker

@MainActor
struct MainCoordinatorTests {
    @Test func emptyLibraryStartsInDiscover() {
        let tab = MainCoordinator.Tab.initial(
            isLibraryEmpty: true,
            hasUpNextEpisodes: true
        )

        #expect(tab == .search)
    }

    @Test func libraryWithUpNextEpisodesStartsInUpNext() {
        let tab = MainCoordinator.Tab.initial(
            isLibraryEmpty: false,
            hasUpNextEpisodes: true
        )

        #expect(tab == .calendar)
    }

    @Test func libraryWithoutUpNextEpisodesStartsInMyShows() {
        let tab = MainCoordinator.Tab.initial(
            isLibraryEmpty: false,
            hasUpNextEpisodes: false
        )

        #expect(tab == .library)
    }
}
