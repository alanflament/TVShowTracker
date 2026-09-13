//
//  MainCoordinatorTests.swift
//  TVShowTrackerTests
//
//  Created by Alan Flament on 16/08/2026.
//

import Foundation
import SwiftData
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

    @Test func crossTabSearchPreservesFlowStateAndRepeatsIdenticalRequests() async throws {
        let fixture = try CoordinatorFixture()
        let coordinator = fixture.makeCoordinator()
        let searchViewModel = coordinator.searchCoordinator.viewModel
        coordinator.libraryCoordinator.viewModel.query = "Library filter"
        coordinator.settingsCoordinator.viewModel.isImporterPresented = true

        coordinator.searchDiscover(for: "Severance")
        let firstRequestID = searchViewModel.searchTaskID
        await searchViewModel.search()

        #expect(coordinator.selectedTab == .search)
        #expect(searchViewModel.query == "Severance")
        guard case let .loaded(catalog) = searchViewModel.state else {
            Issue.record("The cross-tab request did not load")
            return
        }
        #expect(catalog.tvShows.first?.title == "Severance")

        coordinator.selectedTab = .library
        coordinator.searchDiscover(for: "Severance")

        #expect(coordinator.selectedTab == .search)
        #expect(searchViewModel.searchTaskID != firstRequestID)
        #expect(coordinator.libraryCoordinator.viewModel.query == "Library filter")
        #expect(coordinator.settingsCoordinator.viewModel.isImporterPresented)
    }
}
