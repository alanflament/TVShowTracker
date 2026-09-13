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

@MainActor
private struct CoordinatorFixture {
    let followedMediaStore: FollowedMediaStore
    let episodeScheduleStore: EpisodeScheduleStore
    let episodeWatchStore: EpisodeWatchStore
    let refreshStore: FollowedMediaRefreshStore
    let detailsCoordinator: DetailsCoordinator

    init() throws {
        let container = try ModelContainer(
            for: LibraryItemModel.self, WatchedEpisodeModel.self,
            EpisodeScheduleModel.self, EpisodeDetailsModel.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        followedMediaStore = FollowedMediaStore(
            repository: SwiftDataLibraryRepository(modelContext: container.mainContext)
        )
        episodeScheduleStore = EpisodeScheduleStore(
            repository: SwiftDataEpisodeScheduleRepository(modelContext: container.mainContext)
        )
        episodeWatchStore = EpisodeWatchStore(
            repository: SwiftDataEpisodeWatchRepository(modelContext: container.mainContext),
            followedMediaStore: followedMediaStore,
            episodeScheduleStore: episodeScheduleStore
        )
        let showDetailsUseCase = DefaultShowDetailsUseCase(
            tvShowRepository: UnconfiguredTVShowDetailsRepository(),
            animeRepository: AniListAnimeDetailsRepository(httpClient: HTTPClientStub(data: Data(), statusCode: 503))
        )
        refreshStore = FollowedMediaRefreshStore(
            refreshUseCase: DefaultEpisodeScheduleRefreshUseCase(showDetailsUseCase: showDetailsUseCase),
            followedMediaStore: followedMediaStore,
            episodeWatchStore: episodeWatchStore,
            episodeScheduleStore: episodeScheduleStore
        )
        detailsCoordinator = DetailsCoordinator(
            useCase: showDetailsUseCase,
            followedMediaStore: followedMediaStore,
            episodeWatchStore: episodeWatchStore,
            episodeScheduleStore: episodeScheduleStore,
            episodeDetailsStore: EpisodeDetailsStore(
                repository: SwiftDataEpisodeDetailsRepository(modelContext: container.mainContext)
            )
        )
    }

    func makeCoordinator() -> MainCoordinator {
        let workflows = UnavailableWorkflows()
        return MainCoordinator(
            initialTab: .library,
            libraryCoordinator: LibraryCoordinator(
                followedMediaStore: followedMediaStore,
                detailsCoordinator: detailsCoordinator
            ),
            calendarCoordinator: CalendarCoordinator(
                nextEpisodeUseCase: DefaultNextEpisodeUseCase(episodeScheduleStore: episodeScheduleStore),
                followedMediaStore: followedMediaStore,
                episodeWatchStore: episodeWatchStore,
                episodeScheduleStore: episodeScheduleStore,
                followedMediaRefreshStore: refreshStore,
                detailsCoordinator: detailsCoordinator
            ),
            searchCoordinator: SearchCoordinator(
                searchCatalogUseCase: DefaultSearchCatalogUseCase(
                    tvShowRepository: TVShowRepositoryStub(candidates: [.tvShow(id: 1, title: "Severance")]),
                    animeRepository: AnimeRepositoryStub()
                ),
                followedMediaStore: followedMediaStore,
                detailsCoordinator: detailsCoordinator
            ),
            settingsCoordinator: SettingsCoordinator(
                tvTimeImportUseCase: workflows,
                dataExportUseCase: workflows,
                dataImportUseCase: workflows
            )
        )
    }
}

private struct UnavailableWorkflows: TVTimeImportUseCase, DataExportUseCase, DataImportUseCase {
    func export(at _: Date) throws -> Data {
        throw CancellationError()
    }

    func importBackup(
        _: Data,
        onProgress _: @escaping @MainActor (DataImportProgress) -> Void
    ) async throws -> DataImportReport {
        throw CancellationError()
    }

    func importExport(
        at _: URL,
        onProgress _: @escaping @MainActor (TVTimeImportProgress) -> Void
    ) async throws -> TVTimeImportReport {
        throw CancellationError()
    }
}
