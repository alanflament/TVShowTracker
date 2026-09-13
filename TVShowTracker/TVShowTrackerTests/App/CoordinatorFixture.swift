//
//  CoordinatorFixture.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import SwiftData
import Testing
@testable import TVShowTracker

@MainActor
struct CoordinatorFixture {
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
            libraryRepository: SwiftDataLibraryRepository(modelContext: container.mainContext)
        )
        episodeScheduleStore = EpisodeScheduleStore(
            episodeScheduleRepository: SwiftDataEpisodeScheduleRepository(modelContext: container.mainContext)
        )
        episodeWatchStore = EpisodeWatchStore(
            episodeWatchRepository: SwiftDataEpisodeWatchRepository(modelContext: container.mainContext),
            followedMediaStore: followedMediaStore,
            episodeScheduleStore: episodeScheduleStore
        )
        let showDetailsUseCase = DefaultShowDetailsUseCase(
            tvShowDetailsRepository: UnconfiguredTVShowDetailsRepository(),
            animeDetailsRepository: AniListAnimeDetailsRepository(httpClient: HTTPClientStub(data: Data(), statusCode: 503))
        )
        refreshStore = FollowedMediaRefreshStore(
            episodeScheduleRefreshUseCase: DefaultEpisodeScheduleRefreshUseCase(showDetailsUseCase: showDetailsUseCase),
            followedMediaStore: followedMediaStore,
            episodeWatchStore: episodeWatchStore,
            episodeScheduleStore: episodeScheduleStore
        )
        detailsCoordinator = DetailsCoordinator(
            showDetailsUseCase: showDetailsUseCase,
            followedMediaStore: followedMediaStore,
            episodeWatchStore: episodeWatchStore,
            episodeScheduleStore: episodeScheduleStore,
            episodeDetailsStore: EpisodeDetailsStore(
                episodeDetailsRepository: SwiftDataEpisodeDetailsRepository(modelContext: container.mainContext)
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
                nextEpisodeUseCase: DefaultNextEpisodeUseCase(episodeScheduleReader: episodeScheduleStore),
                followedMediaStore: followedMediaStore,
                episodeWatchStore: episodeWatchStore,
                episodeScheduleStore: episodeScheduleStore,
                followedMediaRefreshStore: refreshStore,
                detailsCoordinator: detailsCoordinator
            ),
            searchCoordinator: SearchCoordinator(
                searchCatalogUseCase: DefaultSearchCatalogUseCase(
                    tvShowSearchRepository: TVShowRepositoryStub(candidates: [.tvShow(id: 1, title: "Severance")]),
                    animeSearchRepository: AnimeRepositoryStub()
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
