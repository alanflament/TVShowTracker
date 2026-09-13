//
//  DefaultDataExportUseCase.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/08/2026.
//

import Foundation

@MainActor
final class DefaultDataExportUseCase: DataExportUseCase {
    private let libraryRepository: any LibraryRepository
    private let episodeWatchRepository: any EpisodeWatchRepository

    init(
        libraryRepository: any LibraryRepository,
        episodeWatchRepository: any EpisodeWatchRepository
    ) {
        self.libraryRepository = libraryRepository
        self.episodeWatchRepository = episodeWatchRepository
    }

    func export(at date: Date = .now) throws -> Data {
        let backup = try TVShowTrackerBackup(
            exportedAt: date,
            media: libraryRepository.loadItems()
                .sorted { $0.id < $1.id }
                .map(BackupMedia.init),
            watchedEpisodes: episodeWatchRepository.loadWatchedEpisodes()
                .sorted { $0.id < $1.id }
                .map(BackupWatchedEpisode.init)
        )
        return try BackupCodec().encode(backup)
    }
}
