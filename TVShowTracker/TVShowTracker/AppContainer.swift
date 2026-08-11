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

    private let searchCatalogUseCase: any SearchCatalogUseCase
    private let showDetailsUseCase: any ShowDetailsUseCase
    private let followedMediaStore: FollowedMediaStore
    private let episodeWatchStore: EpisodeWatchStore
    private let episodeScheduleStore: EpisodeScheduleStore
    private let followedMediaRefreshStore: FollowedMediaRefreshStore

    init() {
        modelContainer = Self.makeModelContainer()

        followedMediaStore = FollowedMediaStore(
            repository: SwiftDataLibraryRepository(modelContext: modelContainer.mainContext)
        )
        episodeWatchStore = EpisodeWatchStore(
            repository: SwiftDataEpisodeWatchRepository(modelContext: modelContainer.mainContext)
        )
        episodeScheduleStore = EpisodeScheduleStore(
            repository: SwiftDataEpisodeScheduleRepository(modelContext: modelContainer.mainContext)
        )

        let tvShowRepository: any TVShowSearchRepository

        if let tmdbAccessToken = Self.tmdbAccessToken {
            tvShowRepository = TMDBTVSearchRepository(
                accessToken: tmdbAccessToken,
                language: Locale.current.language.languageCode?.identifier ?? "en-US"
            )
        } else {
            tvShowRepository = UnconfiguredTVShowSearchRepository()
        }

        let animeSearchRepository = FallbackAnimeSearchRepository(
            primary: AniListAnimeSearchRepository(),
            fallback: JikanAnimeSearchRepository()
        )

        searchCatalogUseCase = DefaultSearchCatalogUseCase(
            tvShowRepository: tvShowRepository,
            animeRepository: animeSearchRepository
        )

        let language = Locale.current.language.languageCode?.identifier ?? "en-US"
        let detailsTVRepository: any TVShowDetailsRepository
        if let tmdbAccessToken = Self.tmdbAccessToken {
            detailsTVRepository = TMDBShowDetailsRepository(
                accessToken: tmdbAccessToken,
                language: language
            )
        } else {
            detailsTVRepository = UnconfiguredTVShowDetailsRepository()
        }

        showDetailsUseCase = DefaultShowDetailsUseCase(
            tvShowRepository: detailsTVRepository,
            animeRepository: AniListAnimeDetailsRepository()
        )
        followedMediaRefreshStore = FollowedMediaRefreshStore(
            refreshUseCase: DefaultEpisodeScheduleRefreshUseCase(
                showDetailsUseCase: showDetailsUseCase
            ),
            followedMediaStore: followedMediaStore,
            episodeScheduleStore: episodeScheduleStore
        )
    }

    private static func makeModelContainer() -> ModelContainer {
        do {
            return try ModelContainer(
                for: LibraryItemModel.self,
                WatchedEpisodeModel.self,
                EpisodeScheduleModel.self
            )
        } catch {
            fatalError("Unable to create the SwiftData container: \(error)")
        }
    }

    func makeAppCoordinator() -> AppCoordinator {
        AppCoordinator(
            container: self,
            followedMediaRefreshStore: followedMediaRefreshStore
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
            useCase: showDetailsUseCase,
            followedMediaStore: followedMediaStore,
            episodeWatchStore: episodeWatchStore
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
                episodeScheduleStore: episodeScheduleStore
            ),
            followedMediaStore: followedMediaStore,
            episodeWatchStore: episodeWatchStore,
            episodeScheduleStore: episodeScheduleStore,
            followedMediaRefreshStore: followedMediaRefreshStore
        )
    }

    func makeSettingsCoordinator() -> SettingsCoordinator {
        SettingsCoordinator(
            tvTimeImportUseCase: DefaultTVTimeImportUseCase(
                exportParser: TVTimeCSVExportParser(),
                searchCatalogUseCase: searchCatalogUseCase,
                showDetailsUseCase: showDetailsUseCase,
                followedMediaStore: followedMediaStore,
                episodeWatchStore: episodeWatchStore,
                candidateMatcher: TVTimeSearchCandidateMatcher()
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
