//
//  TVTimeImportTests.swift
//  TVShowTrackerTests
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation
import SwiftData
import Testing
@testable import TVShowTracker

@MainActor
struct TVTimeImportTests {
    @Test func addsAnExactMatchAndRestoresWatchedEpisodes() async throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: LibraryItemModel.self,
            WatchedEpisodeModel.self,
            EpisodeScheduleModel.self,
            configurations: configuration
        )
        let followedMediaStore = FollowedMediaStore(
            repository: SwiftDataLibraryRepository(modelContext: container.mainContext)
        )
        let episodeWatchStore = EpisodeWatchStore(
            repository: SwiftDataEpisodeWatchRepository(modelContext: container.mainContext)
        )
        let episodeScheduleStore = EpisodeScheduleStore(
            repository: SwiftDataEpisodeScheduleRepository(modelContext: container.mainContext)
        )
        let candidate = makeCandidate()
        let episode = makeEpisode()
        let useCase = makeUseCase(
            candidate: candidate,
            episode: episode,
            followedMediaStore: followedMediaStore,
            episodeWatchStore: episodeWatchStore,
            episodeScheduleStore: episodeScheduleStore
        )

        let report = try await useCase.importExport(at: URL(filePath: "/unused")) { _ in }

        #expect(report.addedShowCount == 1)
        #expect(report.restoredEpisodeCount == 1)
        #expect(followedMediaStore.contains(candidate))
        #expect(episodeWatchStore.isWatched(episode))
        #expect(episodeScheduleStore.schedule(for: LibraryItem(candidate: candidate))?.seasons == [ShowSeason(
            provider: episode.provider,
            showID: episode.showID,
            number: episode.seasonNumber,
            name: "Season \(episode.seasonNumber)",
            episodes: [episode]
        )])
    }

    @Test func savesEpisodeScheduleForAnImportedShowWithoutWatchedEpisodes() async throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: LibraryItemModel.self,
            WatchedEpisodeModel.self,
            EpisodeScheduleModel.self,
            configurations: configuration
        )
        let followedMediaStore = FollowedMediaStore(
            repository: SwiftDataLibraryRepository(modelContext: container.mainContext)
        )
        let episodeWatchStore = EpisodeWatchStore(
            repository: SwiftDataEpisodeWatchRepository(modelContext: container.mainContext)
        )
        let episodeScheduleStore = EpisodeScheduleStore(
            repository: SwiftDataEpisodeScheduleRepository(modelContext: container.mainContext)
        )
        let candidate = makeCandidate()
        let episode = makeEpisode()
        let useCase = makeUseCase(
            candidate: candidate,
            episode: episode,
            followedMediaStore: followedMediaStore,
            episodeWatchStore: episodeWatchStore,
            episodeScheduleStore: episodeScheduleStore,
            watchedEpisodes: []
        )

        let report = try await useCase.importExport(at: URL(filePath: "/unused")) { _ in }

        #expect(report.addedShowCount == 1)
        #expect(episodeScheduleStore.schedule(for: LibraryItem(candidate: candidate)) != nil)
    }
}

private func makeCandidate() -> SearchCandidate {
    SearchCandidate(
        provider: .tmdb,
        providerID: 42,
        kind: .tvShow,
        title: "The Bear",
        alternateTitle: nil,
        posterURL: nil,
        releaseYear: nil,
        totalEpisodeCount: nil,
        status: nil,
        nextEpisodeNumber: nil,
        nextEpisodeAirDate: nil
    )
}

private func makeEpisode() -> ShowEpisode {
    ShowEpisode(
        provider: .tmdb,
        showID: 42,
        seasonNumber: 1,
        number: 3,
        title: "Episode 3",
        overview: nil,
        airDate: .distantPast,
        stillURL: nil,
        runtimeMinutes: nil
    )
}

@MainActor
private func makeUseCase(
    candidate: SearchCandidate,
    episode: ShowEpisode,
    followedMediaStore: FollowedMediaStore,
    episodeWatchStore: EpisodeWatchStore,
    episodeScheduleStore: EpisodeScheduleStore,
    watchedEpisodes: [TVTimeWatchedEpisode] = [TVTimeWatchedEpisode(
        showTitle: "The Bear",
        seasonNumber: 1,
        episodeNumber: 3,
        watchedAt: .distantPast
    )]
) -> DefaultTVTimeImportUseCase {
    let export = TVTimeExport(
        followedShows: [TVTimeShow(title: "The Bear")],
        watchedEpisodes: watchedEpisodes
    )

    return DefaultTVTimeImportUseCase(
        exportParser: TVTimeExportParserStub(export: export),
        searchCatalogUseCase: SearchCatalogUseCaseStub(candidate: candidate),
        showDetailsUseCase: ShowDetailsUseCaseStub(episode: episode),
        followedMediaStore: followedMediaStore,
        episodeWatchStore: episodeWatchStore,
        episodeScheduleStore: episodeScheduleStore,
        candidateMatcher: TVTimeSearchCandidateMatcher()
    )
}

private struct TVTimeExportParserStub: TVTimeExportParsing {
    let export: TVTimeExport

    func parseExport(at _: URL) throws -> TVTimeExport {
        export
    }
}

private struct SearchCatalogUseCaseStub: SearchCatalogUseCase {
    let candidate: SearchCandidate

    func search(matching _: String) async -> SearchCatalog {
        SearchCatalog(
            tvShows: [candidate],
            anime: [],
            unavailableProviders: [],
            providerErrors: [:]
        )
    }
}

private struct ShowDetailsUseCaseStub: ShowDetailsUseCase {
    let episode: ShowEpisode

    func fetchDetails(for _: SearchCandidate) async throws -> ShowDetails {
        throw TVTimeImportTestError.expectedFailure
    }

    func fetchEpisodes(for _: SearchCandidate) async throws -> [ShowSeason] {
        [ShowSeason(
            provider: episode.provider,
            showID: episode.showID,
            number: episode.seasonNumber,
            name: "Season \(episode.seasonNumber)",
            episodes: [episode]
        )]
    }
}

private enum TVTimeImportTestError: Error {
    case expectedFailure
}
