//
//  DefaultDataImportUseCaseTests.swift
//  TVShowTrackerTests
//
//  Created by Alan Flament on 13/08/2026.
//

import Foundation
import SwiftData
import Testing
@testable import TVShowTracker

@MainActor
struct DefaultDataImportUseCaseTests {
    @Test func importsExportedDataWithoutDeletingExistingItems() async throws {
        let sourceContainer = try makeContainer()
        let sourceLibrary = SwiftDataLibraryRepository(modelContext: sourceContainer.mainContext)
        let sourceHistory = SwiftDataEpisodeWatchRepository(modelContext: sourceContainer.mainContext)
        let watchedAt = try #require(ISO8601DateFormatter().date(from: "2026-08-02T20:30:00Z"))
        try sourceLibrary.save(makeItem(id: 95396, title: "Severance", trackingStatus: .completed))
        try sourceHistory.save(WatchedEpisode(id: "tmdb:95396:1:1", watchedAt: watchedAt))
        let data = try DefaultDataExportUseCase(
            libraryRepository: sourceLibrary,
            episodeWatchRepository: sourceHistory
        ).export(at: .now)

        let destinationContainer = try makeContainer()
        let destinationLibrary = SwiftDataLibraryRepository(modelContext: destinationContainer.mainContext)
        let destinationHistory = SwiftDataEpisodeWatchRepository(modelContext: destinationContainer.mainContext)
        let followedMediaStore = FollowedMediaStore(repository: destinationLibrary)
        let episodeScheduleStore = EpisodeScheduleStore(
            repository: SwiftDataEpisodeScheduleRepository(modelContext: destinationContainer.mainContext)
        )
        try destinationLibrary.save(makeItem(id: 1396, title: "Breaking Bad", trackingStatus: .watching))
        try destinationHistory.save(WatchedEpisode(id: "tmdb:95396:1:1", watchedAt: .now))
        let useCase = DefaultDataImportUseCase(
            libraryRepository: destinationLibrary,
            episodeWatchRepository: destinationHistory,
            showDetailsUseCase: BackupImportDetailsUseCaseStub(),
            followedMediaStore: followedMediaStore,
            episodeScheduleStore: episodeScheduleStore,
            didImport: {
                followedMediaStore.reload()
            }
        )

        let report = try await useCase.importBackup(data)

        #expect(report == DataImportReport(
            mediaCount: 1,
            watchedEpisodeCount: 1,
            refreshedMediaCount: 1,
            refreshedScheduleCount: 1
        ))
        #expect(try destinationLibrary.loadItems().map(\.title).sorted() == ["Breaking Bad", "Severance"])
        #expect(try destinationLibrary.loadItems().first { $0.title == "Severance" }?.trackingStatus == .completed)
        #expect(try destinationHistory.loadWatchedEpisodes() == [
            WatchedEpisode(id: "tmdb:95396:1:1", watchedAt: watchedAt)
        ])
    }

    @Test func refreshesMissingPostersAndPersistsSchedulesAfterImport() async throws {
        let sourceContainer = try makeContainer()
        let sourceLibrary = SwiftDataLibraryRepository(modelContext: sourceContainer.mainContext)
        let sourceHistory = SwiftDataEpisodeWatchRepository(modelContext: sourceContainer.mainContext)
        try sourceLibrary.save(makeItem(id: 95396, title: "Severance", trackingStatus: .completed))
        let data = try DefaultDataExportUseCase(
            libraryRepository: sourceLibrary,
            episodeWatchRepository: sourceHistory
        ).export(at: .now)

        let destinationContainer = try makeContainer()
        let destinationLibrary = SwiftDataLibraryRepository(modelContext: destinationContainer.mainContext)
        let followedMediaStore = FollowedMediaStore(repository: destinationLibrary)
        let episodeScheduleStore = EpisodeScheduleStore(
            repository: SwiftDataEpisodeScheduleRepository(modelContext: destinationContainer.mainContext)
        )
        let posterURL = try #require(URL(string: "https://example.com/refreshed-poster.jpg"))
        let useCase = DefaultDataImportUseCase(
            libraryRepository: destinationLibrary,
            episodeWatchRepository: SwiftDataEpisodeWatchRepository(modelContext: destinationContainer.mainContext),
            showDetailsUseCase: BackupImportDetailsUseCaseStub(posterURL: posterURL),
            followedMediaStore: followedMediaStore,
            episodeScheduleStore: episodeScheduleStore,
            didImport: {
                followedMediaStore.reload()
            }
        )

        let report = try await useCase.importBackup(data)
        let importedItem = try #require(followedMediaStore.items.first)

        #expect(importedItem.posterURL == posterURL)
        #expect(importedItem.trackingStatus == .completed)
        #expect(episodeScheduleStore.schedule(for: importedItem)?.seasons.count == 1)
        #expect(report.refreshedMediaCount == 1)
        #expect(report.refreshedScheduleCount == 1)
    }

    @Test func keepsRestoredDataWhenProviderEnrichmentFails() async throws {
        let sourceContainer = try makeContainer()
        let sourceLibrary = SwiftDataLibraryRepository(modelContext: sourceContainer.mainContext)
        let sourceHistory = SwiftDataEpisodeWatchRepository(modelContext: sourceContainer.mainContext)
        try sourceLibrary.save(makeItem(id: 95396, title: "Severance", trackingStatus: .planToWatch))
        let data = try DefaultDataExportUseCase(
            libraryRepository: sourceLibrary,
            episodeWatchRepository: sourceHistory
        ).export(at: .now)

        let destinationContainer = try makeContainer()
        let destinationLibrary = SwiftDataLibraryRepository(modelContext: destinationContainer.mainContext)
        let followedMediaStore = FollowedMediaStore(repository: destinationLibrary)
        let episodeScheduleStore = EpisodeScheduleStore(
            repository: SwiftDataEpisodeScheduleRepository(modelContext: destinationContainer.mainContext)
        )
        let useCase = DefaultDataImportUseCase(
            libraryRepository: destinationLibrary,
            episodeWatchRepository: SwiftDataEpisodeWatchRepository(modelContext: destinationContainer.mainContext),
            showDetailsUseCase: BackupImportDetailsUseCaseStub(shouldFail: true),
            followedMediaStore: followedMediaStore,
            episodeScheduleStore: episodeScheduleStore,
            didImport: {
                followedMediaStore.reload()
            }
        )

        let report = try await useCase.importBackup(data)

        #expect(followedMediaStore.items.map(\.title) == ["Severance"])
        #expect(followedMediaStore.items.first?.trackingStatus == .planToWatch)
        #expect(report.mediaRefreshFailureCount == 1)
        #expect(report.refreshedScheduleCount == 0)
    }

    @Test func rejectsUnsupportedSchemaBeforeWriting() async throws {
        let container = try makeContainer()
        let library = SwiftDataLibraryRepository(modelContext: container.mainContext)
        let history = SwiftDataEpisodeWatchRepository(modelContext: container.mainContext)
        let followedMediaStore = FollowedMediaStore(repository: library)
        let useCase = DefaultDataImportUseCase(
            libraryRepository: library,
            episodeWatchRepository: history,
            showDetailsUseCase: BackupImportDetailsUseCaseStub(),
            followedMediaStore: followedMediaStore,
            episodeScheduleStore: EpisodeScheduleStore(
                repository: SwiftDataEpisodeScheduleRepository(modelContext: container.mainContext)
            )
        )
        let data = Data("""
        {
          "schemaVersion": 2,
          "exportedAt": "2026-08-13T19:00:00Z",
          "media": [],
          "watchedEpisodes": []
        }
        """.utf8)

        await #expect(throws: DataImportError.unsupportedSchemaVersion(2)) {
            try await useCase.importBackup(data)
        }
        #expect(try library.loadItems().isEmpty)
        #expect(try history.loadWatchedEpisodes().isEmpty)
    }

    @Test func rejectsInconsistentIdentityBeforeWritingAnyRecord() async throws {
        let container = try makeContainer()
        let library = SwiftDataLibraryRepository(modelContext: container.mainContext)
        let history = SwiftDataEpisodeWatchRepository(modelContext: container.mainContext)
        let validItem = makeItem(id: 1, title: "Valid", trackingStatus: .watching)
        let invalidItem = makeItem(id: 2, title: "Invalid", trackingStatus: .watching)
        let data = try BackupCodec().encode(TVShowTrackerBackup(
            exportedAt: .now,
            media: [BackupMedia(item: validItem), BackupMedia(item: invalidItem)],
            watchedEpisodes: []
        ))
        let json = try #require(String(data: data, encoding: .utf8))
            .replacingOccurrences(of: "tmdb:2", with: "tmdb:999")
        let useCase = DefaultDataImportUseCase(
            libraryRepository: library,
            episodeWatchRepository: history,
            showDetailsUseCase: BackupImportDetailsUseCaseStub(),
            followedMediaStore: FollowedMediaStore(repository: library),
            episodeScheduleStore: EpisodeScheduleStore(
                repository: SwiftDataEpisodeScheduleRepository(modelContext: container.mainContext)
            )
        )

        await #expect(throws: DataImportError.invalidRecord("tmdb:999")) {
            try await useCase.importBackup(Data(json.utf8))
        }
        #expect(try library.loadItems().isEmpty)
        #expect(try history.loadWatchedEpisodes().isEmpty)
    }

    private func makeItem(
        id: Int,
        title: String,
        trackingStatus: TrackingStatus
    ) -> LibraryItem {
        LibraryItem(
            candidate: MediaCandidate(
                provider: .tmdb,
                providerID: id,
                kind: .tvShow,
                title: title,
                alternateTitle: nil,
                posterURL: nil,
                releaseYear: nil,
                totalEpisodeCount: nil,
                status: .finished,
                nextEpisodeNumber: nil,
                nextEpisodeAirDate: nil
            ),
            trackingStatus: trackingStatus
        )
    }

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: LibraryItemModel.self,
            WatchedEpisodeModel.self,
            EpisodeScheduleModel.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }
}

private struct BackupImportDetailsUseCaseStub: ShowDetailsUseCase {
    let posterURL: URL?
    let shouldFail: Bool

    init(posterURL: URL? = nil, shouldFail: Bool = false) {
        self.posterURL = posterURL
        self.shouldFail = shouldFail
    }

    func fetchDetails(for candidate: MediaCandidate) async throws -> ShowDetails {
        if shouldFail {
            throw BackupImportTestError.expectedFailure
        }
        return ShowDetails(
            provider: candidate.provider,
            providerID: candidate.providerID,
            kind: candidate.kind,
            title: candidate.title,
            alternateTitle: candidate.alternateTitle,
            overview: nil,
            posterURL: posterURL,
            backdropURL: nil,
            releaseYear: candidate.releaseYear,
            status: candidate.status,
            totalEpisodeCount: candidate.totalEpisodeCount,
            genres: [],
            seasonSummaries: []
        )
    }

    func fetchEpisodes(for candidate: MediaCandidate) async throws -> [ShowSeason] {
        if shouldFail {
            throw BackupImportTestError.expectedFailure
        }
        return [ShowSeason(
            provider: candidate.provider,
            showID: candidate.providerID,
            number: 1,
            name: "Season 1",
            episodes: []
        )]
    }
}

private enum BackupImportTestError: Error {
    case expectedFailure
}
