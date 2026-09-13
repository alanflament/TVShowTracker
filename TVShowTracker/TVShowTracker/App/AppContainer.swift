//
//  AppContainer.swift
//  TVShowTracker
//
//  Created by Alan Flament on 30/07/2026.
//

import Foundation
import SwiftData

@MainActor
final class AppContainer {
    let modelContainer: ModelContainer

    private let libraryRepository: any LibraryRepository
    private let episodeWatchRepository: any EpisodeWatchRepository
    private let searchCatalogUseCase: any SearchCatalogUseCase
    private let showDetailsUseCase: any ShowDetailsUseCase
    private let followedMediaStore: FollowedMediaStore
    private let episodeWatchStore: EpisodeWatchStore
    private let episodeScheduleStore: EpisodeScheduleStore
    private let episodeDetailsStore: EpisodeDetailsStore
    private let followedMediaRefreshStore: FollowedMediaRefreshStore

    init() {
        modelContainer = Self.makeModelContainer(isStoredInMemoryOnly: Self.usesDemoData)

        libraryRepository = SwiftDataLibraryRepository(modelContext: modelContainer.mainContext)
        episodeWatchRepository = SwiftDataEpisodeWatchRepository(modelContext: modelContainer.mainContext)
        followedMediaStore = FollowedMediaStore(libraryRepository: libraryRepository)
        episodeScheduleStore = EpisodeScheduleStore(
            episodeScheduleRepository: SwiftDataEpisodeScheduleRepository(modelContext: modelContainer.mainContext)
        )
        episodeWatchStore = EpisodeWatchStore(
            episodeWatchRepository: episodeWatchRepository,
            followedMediaStore: followedMediaStore,
            episodeScheduleStore: episodeScheduleStore
        )
        episodeDetailsStore = EpisodeDetailsStore(
            episodeDetailsRepository: SwiftDataEpisodeDetailsRepository(modelContext: modelContainer.mainContext)
        )
        Self.seedDemoStateIfNeeded(followedMediaStore, episodeScheduleStore, episodeWatchStore, episodeDetailsStore)

        let services = AppProviderServices(
            tmdbAccessToken: Self.tmdbAccessToken,
            language: Locale.current.language.languageCode?.identifier ?? "en-US"
        )
        searchCatalogUseCase = services.searchCatalogUseCase
        showDetailsUseCase = services.showDetailsUseCase
        followedMediaRefreshStore = FollowedMediaRefreshStore(
            episodeScheduleRefreshUseCase: DefaultEpisodeScheduleRefreshUseCase(
                showDetailsUseCase: showDetailsUseCase
            ),
            followedMediaStore: followedMediaStore,
            episodeWatchStore: episodeWatchStore,
            episodeScheduleStore: episodeScheduleStore
        )
    }

    private static func makeModelContainer(isStoredInMemoryOnly: Bool) -> ModelContainer {
        do {
            return try ModelContainer(
                for: LibraryItemModel.self,
                WatchedEpisodeModel.self,
                EpisodeScheduleModel.self,
                EpisodeDetailsModel.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: isStoredInMemoryOnly)
            )
        } catch {
            fatalError("Unable to create the SwiftData container: \(error)")
        }
    }

    func makeAppCoordinator() -> AppCoordinator {
        AppCoordinator(
            mainCoordinator: MainCoordinator(
                initialTab: initialMainTab,
                libraryCoordinator: makeLibraryCoordinator(),
                calendarCoordinator: makeCalendarCoordinator(),
                searchCoordinator: makeSearchCoordinator(),
                settingsCoordinator: makeSettingsCoordinator()
            ),
            followedMediaRefreshStore: followedMediaRefreshStore
        )
    }

    private var initialMainTab: MainCoordinator.Tab {
        #if DEBUG
            let arguments = ProcessInfo.processInfo.arguments
            if arguments.contains("--library-tab") {
                return .library
            }
            if arguments.contains("--settings-tab") {
                return .settings
            }
            if arguments.contains("--calendar-tab") {
                return .calendar
            }
            if arguments.contains("--discover-tab") {
                return .search
            }
        #endif
        let items = followedMediaStore.items
        let nextEpisodeUseCase = DefaultNextEpisodeUseCase(
            episodeScheduleReader: episodeScheduleStore
        )
        let hasUpNextEpisodes = nextEpisodeUseCase.hasNextEpisode(
            in: items,
            watchedEpisodeIDs: episodeWatchStore.watchedEpisodeIDs,
            now: .now
        )
        return MainCoordinator.Tab.initial(
            isLibraryEmpty: items.isEmpty,
            hasUpNextEpisodes: hasUpNextEpisodes
        )
    }

    func makeSearchCoordinator() -> SearchCoordinator {
        SearchCoordinator(
            searchCatalogUseCase: searchCatalogUseCase,
            followedMediaStore: followedMediaStore,
            detailsCoordinator: makeDetailsCoordinator()
        )
    }

    func makeDetailsCoordinator() -> DetailsCoordinator {
        DetailsCoordinator(
            showDetailsUseCase: showDetailsUseCase,
            followedMediaStore: followedMediaStore,
            episodeWatchStore: episodeWatchStore,
            episodeScheduleStore: episodeScheduleStore,
            episodeDetailsStore: episodeDetailsStore
        )
    }

    func makeLibraryCoordinator() -> LibraryCoordinator {
        LibraryCoordinator(
            followedMediaStore: followedMediaStore,
            detailsCoordinator: makeDetailsCoordinator()
        )
    }

    func makeCalendarCoordinator() -> CalendarCoordinator {
        CalendarCoordinator(
            nextEpisodeUseCase: DefaultNextEpisodeUseCase(
                episodeScheduleReader: episodeScheduleStore
            ),
            followedMediaStore: followedMediaStore,
            episodeWatchStore: episodeWatchStore,
            episodeScheduleStore: episodeScheduleStore,
            followedMediaRefreshStore: followedMediaRefreshStore,
            detailsCoordinator: makeDetailsCoordinator()
        )
    }

    func makeSettingsCoordinator() -> SettingsCoordinator {
        SettingsCoordinator(
            tvTimeImportUseCase: DefaultTVTimeImportUseCase(
                tvTimeExportParser: TVTimeCSVExportParser(),
                searchCatalogUseCase: searchCatalogUseCase,
                showDetailsUseCase: showDetailsUseCase,
                followedMediaStore: followedMediaStore,
                episodeWatchStore: episodeWatchStore,
                episodeScheduleStore: episodeScheduleStore,
                candidateMatcher: TVTimeSearchCandidateMatcher()
            ),
            dataExportUseCase: DefaultDataExportUseCase(
                libraryRepository: libraryRepository,
                episodeWatchRepository: episodeWatchRepository
            ),
            dataImportUseCase: DefaultDataImportUseCase(
                libraryRepository: libraryRepository,
                episodeWatchRepository: episodeWatchRepository,
                showDetailsUseCase: showDetailsUseCase,
                followedMediaStore: followedMediaStore,
                episodeScheduleStore: episodeScheduleStore,
                didImport: { [followedMediaStore, episodeWatchStore] in
                    followedMediaStore.reload()
                    episodeWatchStore.reload()
                }
            )
        )
    }

    private static var tmdbAccessToken: String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "TMDBAccessToken") as? String else {
            return nil
        }

        let token = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return token.isEmpty ? nil : token
    }
}
