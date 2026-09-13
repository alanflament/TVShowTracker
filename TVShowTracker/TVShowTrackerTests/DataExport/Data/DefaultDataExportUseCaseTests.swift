//
//  DefaultDataExportUseCaseTests.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import SwiftData
import Testing
@testable import TVShowTracker

@MainActor
struct DefaultDataExportUseCaseTests {
    @Test func exportsVersionedPortableUserData() throws {
        let container = try makeContainer()
        let libraryRepository = SwiftDataLibraryRepository(modelContext: container.mainContext)
        let episodeWatchRepository = SwiftDataEpisodeWatchRepository(modelContext: container.mainContext)
        let addedAt = try #require(ISO8601DateFormatter().date(from: "2026-08-01T10:00:00Z"))
        let watchedAt = try #require(ISO8601DateFormatter().date(from: "2026-08-02T20:30:00Z"))
        let exportedAt = try #require(ISO8601DateFormatter().date(from: "2026-08-13T19:00:00Z"))
        let candidate = MediaCandidate(
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

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: LibraryItemModel.self,
            WatchedEpisodeModel.self,
            EpisodeScheduleModel.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }
}
