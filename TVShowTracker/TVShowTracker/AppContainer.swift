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

        let aniListHTTPClient = Self.makeAniListHTTPClient()
        let animeSearchRepository = Self.makeAnimeSearchRepository(aniListHTTPClient: aniListHTTPClient)
        let tvShowRepository: any TVShowSearchRepository

        if let tmdbAccessToken = Self.tmdbAccessToken {
            tvShowRepository = TMDBTVSearchRepository(
                accessToken: tmdbAccessToken,
                language: Locale.current.language.languageCode?.identifier ?? "en-US"
            )
        } else {
            tvShowRepository = UnconfiguredTVShowSearchRepository()
        }

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
            animeRepository: AniListAnimeDetailsRepository(httpClient: aniListHTTPClient)
        )
        followedMediaRefreshStore = FollowedMediaRefreshStore(
            refreshUseCase: DefaultEpisodeScheduleRefreshUseCase(
                showDetailsUseCase: showDetailsUseCase
            ),
            followedMediaStore: followedMediaStore,
            episodeWatchStore: episodeWatchStore,
            episodeScheduleStore: episodeScheduleStore
        )
    }

    private static func makeAniListHTTPClient() -> any HTTPClient {
        RateLimitedHTTPClient(client: URLSessionHTTPClient(), minimumInterval: 2.1)
    }

    private static func makeAnimeSearchRepository(
        aniListHTTPClient: any HTTPClient
    ) -> any AnimeSearchRepository {
        let jikanHTTPClient = RateLimitedHTTPClient(
            client: URLSessionHTTPClient(),
            minimumInterval: 1.05
        )
        return FallbackAnimeSearchRepository(
            primary: AniListAnimeSearchRepository(httpClient: aniListHTTPClient),
            fallback: JikanAnimeSearchRepository(httpClient: jikanHTTPClient)
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
            followedMediaRefreshStore: followedMediaRefreshStore,
            initialTab: initialMainTab
        )
    }

    private var initialMainTab: MainCoordinator.Tab {
        let items = followedMediaStore.items
        let nextEpisodeUseCase = DefaultNextEpisodeUseCase(
            episodeScheduleStore: episodeScheduleStore
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
            ),
            dataExportUseCase: DefaultDataExportUseCase(
                libraryRepository: SwiftDataLibraryRepository(modelContext: modelContainer.mainContext),
                episodeWatchRepository: SwiftDataEpisodeWatchRepository(modelContext: modelContainer.mainContext)
            ),
            dataImportUseCase: DefaultDataImportUseCase(
                libraryRepository: SwiftDataLibraryRepository(modelContext: modelContainer.mainContext),
                episodeWatchRepository: SwiftDataEpisodeWatchRepository(modelContext: modelContainer.mainContext),
                showDetailsUseCase: showDetailsUseCase,
                followedMediaStore: followedMediaStore,
                episodeScheduleStore: episodeScheduleStore,
                didImport: {
                    self.followedMediaStore.reload()
                    self.episodeWatchStore.reload()
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
