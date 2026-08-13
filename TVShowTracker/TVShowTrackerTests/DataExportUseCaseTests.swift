//
//  DataExportUseCaseTests.swift
//  TVShowTrackerTests
//
//  Created by Alan Flament on 13/08/2026.
//

import Foundation
import SwiftData
import Testing
@testable import TVShowTracker

@MainActor
struct DataExportUseCaseTests {
    @Test func exportsVersionedPortableUserData() throws {
        let container = try makeContainer()
        let libraryRepository = SwiftDataLibraryRepository(modelContext: container.mainContext)
        let episodeWatchRepository = SwiftDataEpisodeWatchRepository(modelContext: container.mainContext)
        let addedAt = try #require(ISO8601DateFormatter().date(from: "2026-08-01T10:00:00Z"))
        let watchedAt = try #require(ISO8601DateFormatter().date(from: "2026-08-02T20:30:00Z"))
        let exportedAt = try #require(ISO8601DateFormatter().date(from: "2026-08-13T19:00:00Z"))
        let candidate = SearchCandidate(
            provider: .tmdb,
            providerID: 95396,
            kind: .tvShow,
            title: "Severance",
            alternateTitle: nil,
            posterURL: URL(string: "https://example.com/poster.jpg"),
            releaseYear: 2022,
            totalEpisodeCount: 19,
            status: .airing,
            nextEpisodeNumber: nil,
            nextEpisodeAirDate: nil
        )
        try libraryRepository.save(LibraryItem(
            candidate: candidate,
            addedAt: addedAt,
            trackingStatus: .watching
        ))
        try episodeWatchRepository.save(WatchedEpisode(
            id: "tmdb:95396:1:1",
            watchedAt: watchedAt
        ))
        let useCase = DefaultDataExportUseCase(
            libraryRepository: libraryRepository,
            episodeWatchRepository: episodeWatchRepository
        )

        let data = try useCase.export(at: exportedAt)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(TVShowTrackerBackup.self, from: data)

        #expect(backup.schemaVersion == 1)
        #expect(backup.exportedAt == exportedAt)
        #expect(backup.media.map(\.id) == ["tmdb:95396"])
        #expect(backup.media.first?.trackingStatus == .watching)
        #expect(backup.media.first?.providerStatus == .airing)
        #expect(backup.watchedEpisodes == [
            BackupWatchedEpisode(episode: WatchedEpisode(
                id: "tmdb:95396:1:1",
                watchedAt: watchedAt
            ))
        ])
        let json = try #require(String(data: data, encoding: .utf8))
        #expect(json.contains("\"schemaVersion\" : 1"))
    }

    @Test func importsExportedDataWithoutDeletingExistingItems() throws {
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
        try destinationLibrary.save(makeItem(id: 1396, title: "Breaking Bad", trackingStatus: .watching))
        try destinationHistory.save(WatchedEpisode(id: "tmdb:95396:1:1", watchedAt: .now))
        let useCase = DefaultDataImportUseCase(
            libraryRepository: destinationLibrary,
            episodeWatchRepository: destinationHistory
        )

        let report = try useCase.importBackup(data)

        #expect(report == DataImportReport(mediaCount: 1, watchedEpisodeCount: 1))
        #expect(try destinationLibrary.loadItems().map(\.title).sorted() == ["Breaking Bad", "Severance"])
        #expect(try destinationLibrary.loadItems().first { $0.title == "Severance" }?.trackingStatus == .completed)
        #expect(try destinationHistory.loadWatchedEpisodes() == [
            WatchedEpisode(id: "tmdb:95396:1:1", watchedAt: watchedAt)
        ])
    }

    @Test func rejectsUnsupportedSchemaBeforeWriting() throws {
        let container = try makeContainer()
        let library = SwiftDataLibraryRepository(modelContext: container.mainContext)
        let history = SwiftDataEpisodeWatchRepository(modelContext: container.mainContext)
        let useCase = DefaultDataImportUseCase(
            libraryRepository: library,
            episodeWatchRepository: history
        )
        let data = Data("""
        {
          "schemaVersion": 2,
          "exportedAt": "2026-08-13T19:00:00Z",
          "media": [],
          "watchedEpisodes": []
        }
        """.utf8)

        #expect(throws: DataImportError.unsupportedSchemaVersion(2)) {
            try useCase.importBackup(data)
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
            candidate: SearchCandidate(
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
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }
}
