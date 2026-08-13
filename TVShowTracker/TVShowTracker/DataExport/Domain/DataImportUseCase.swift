//
//  DataImportUseCase.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/08/2026.
//

import Foundation

struct DataImportReport: Equatable, Sendable {
    let mediaCount: Int
    let watchedEpisodeCount: Int
}

enum DataImportError: LocalizedError, Equatable {
    case unsupportedSchemaVersion(Int)

    var errorDescription: String? {
        switch self {
        case let .unsupportedSchemaVersion(version):
            "This backup uses unsupported schema version \(version). Update TVShowTracker and try again."
        }
    }
}

@MainActor
protocol DataImportUseCase {
    func importBackup(_ data: Data) throws -> DataImportReport
}

@MainActor
final class DefaultDataImportUseCase: DataImportUseCase {
    private let libraryRepository: any LibraryRepository
    private let episodeWatchRepository: any EpisodeWatchRepository
    private let didImport: () -> Void

    init(
        libraryRepository: any LibraryRepository,
        episodeWatchRepository: any EpisodeWatchRepository,
        didImport: @escaping () -> Void = {}
    ) {
        self.libraryRepository = libraryRepository
        self.episodeWatchRepository = episodeWatchRepository
        self.didImport = didImport
    }

    func importBackup(_ data: Data) throws -> DataImportReport {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(TVShowTrackerBackup.self, from: data)
        guard backup.schemaVersion == TVShowTrackerBackup.currentSchemaVersion else {
            throw DataImportError.unsupportedSchemaVersion(backup.schemaVersion)
        }

        let media = Dictionary(
            backup.media.map { ($0.id, $0.asDomain) },
            uniquingKeysWith: { _, latest in latest }
        ).values.sorted { $0.id < $1.id }
        let watchedEpisodes = Dictionary(
            backup.watchedEpisodes.map { ($0.id, $0.asDomain) },
            uniquingKeysWith: { _, latest in latest }
        ).values.sorted { $0.id < $1.id }

        for item in media {
            try libraryRepository.save(item)
        }
        try episodeWatchRepository.save(watchedEpisodes)
        didImport()

        return DataImportReport(
            mediaCount: media.count,
            watchedEpisodeCount: watchedEpisodes.count
        )
    }
}
