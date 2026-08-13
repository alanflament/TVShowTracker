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
    private let episodeDetailsStore: EpisodeDetailsStore
    private let followedMediaRefreshStore: FollowedMediaRefreshStore

    init() {
        modelContainer = Self.makeModelContainer(isStoredInMemoryOnly: Self.usesDemoData)

        followedMediaStore = .init(repository: SwiftDataLibraryRepository(modelContext: modelContainer.mainContext))
        episodeScheduleStore = EpisodeScheduleStore(
            repository: SwiftDataEpisodeScheduleRepository(modelContext: modelContainer.mainContext)
        )
        episodeWatchStore = Self.makeEpisodeWatchStore(modelContainer, followedMediaStore, episodeScheduleStore)
        episodeDetailsStore = .init(
            repository: SwiftDataEpisodeDetailsRepository(modelContext: modelContainer.mainContext)
        )
        Self.seedDemoDataIfNeeded(into: followedMediaStore)

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

    private static func makeEpisodeWatchStore(
        _ modelContainer: ModelContainer,
        _ followedMediaStore: FollowedMediaStore,
        _ episodeScheduleStore: EpisodeScheduleStore
    ) -> EpisodeWatchStore {
        EpisodeWatchStore(
            repository: SwiftDataEpisodeWatchRepository(modelContext: modelContainer.mainContext),
            followedMediaStore: followedMediaStore,
            episodeScheduleStore: episodeScheduleStore
        )
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
                episodeScheduleStore: episodeScheduleStore
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
                exportParser: TVTimeCSVExportParser(),
                searchCatalogUseCase: searchCatalogUseCase,
                showDetailsUseCase: showDetailsUseCase,
                followedMediaStore: followedMediaStore,
                episodeWatchStore: episodeWatchStore,
                episodeScheduleStore: episodeScheduleStore,
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

    private static var usesDemoData: Bool {
        #if DEBUG
            ProcessInfo.processInfo.arguments.contains("--demo-data")
        #else
            false
        #endif
    }

    private static func seedDemoDataIfNeeded(into store: FollowedMediaStore) {
        guard usesDemoData else {
            return
        }

        let samples: [(SearchCandidate, TrackingStatus)] = [
            (demoCandidate(id: 95396, title: "Severance", status: .airing), .watching),
            (demoCandidate(id: 1396, title: "Breaking Bad", status: .finished), .planToWatch),
            (demoCandidate(id: 136_315, title: "The Bear", status: .airing), .paused),
            (demoCandidate(id: 70523, title: "Dark", status: .finished), .completed),
            (demoCandidate(id: 63247, title: "Westworld", status: .cancelled), .dropped)
        ]
        for sample in samples {
            store.addIfMissing(sample.0, trackingStatus: sample.1)
        }
    }

    private static func demoCandidate(
        id: Int,
        title: String,
        status: SearchMediaStatus
    ) -> SearchCandidate {
        SearchCandidate(
            provider: .tmdb,
            providerID: id,
            kind: .tvShow,
            title: title,
            alternateTitle: nil,
            posterURL: nil,
            releaseYear: 2022,
            totalEpisodeCount: 10,
            status: status,
            nextEpisodeNumber: nil,
            nextEpisodeAirDate: nil
        )
    }
}
