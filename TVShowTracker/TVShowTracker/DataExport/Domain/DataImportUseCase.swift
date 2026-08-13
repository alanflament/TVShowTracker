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
    let refreshedMediaCount: Int
    let refreshedScheduleCount: Int

    var mediaRefreshFailureCount: Int {
        mediaCount - refreshedMediaCount
    }
}

struct DataImportProgress: Equatable, Sendable {
    enum Phase: Equatable, Sendable {
        case restoringBackup
        case refreshingMedia
    }

    let phase: Phase
    let completedUnitCount: Int
    let totalUnitCount: Int
    let currentTitle: String?
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
    func importBackup(
        _ data: Data,
        onProgress: @escaping @MainActor (DataImportProgress) -> Void
    ) async throws -> DataImportReport
}

@MainActor
final class DefaultDataImportUseCase: DataImportUseCase {
    private static let maximumConcurrentRefreshes = 4
    private let libraryRepository: any LibraryRepository
    private let episodeWatchRepository: any EpisodeWatchRepository
    private let showDetailsUseCase: any ShowDetailsUseCase
    private let followedMediaStore: FollowedMediaStore
    private let episodeScheduleStore: EpisodeScheduleStore
    private let didImport: () -> Void

    init(
        libraryRepository: any LibraryRepository,
        episodeWatchRepository: any EpisodeWatchRepository,
        showDetailsUseCase: any ShowDetailsUseCase,
        followedMediaStore: FollowedMediaStore,
        episodeScheduleStore: EpisodeScheduleStore,
        didImport: @escaping () -> Void = {}
    ) {
        self.libraryRepository = libraryRepository
        self.episodeWatchRepository = episodeWatchRepository
        self.showDetailsUseCase = showDetailsUseCase
        self.followedMediaStore = followedMediaStore
        self.episodeScheduleStore = episodeScheduleStore
        self.didImport = didImport
    }

    func importBackup(
        _ data: Data,
        onProgress: @escaping @MainActor (DataImportProgress) -> Void = { _ in }
    ) async throws -> DataImportReport {
        onProgress(DataImportProgress(
            phase: .restoringBackup,
            completedUnitCount: 0,
            totalUnitCount: 1,
            currentTitle: nil
        ))
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

        onProgress(DataImportProgress(
            phase: .restoringBackup,
            completedUnitCount: 1,
            totalUnitCount: 1,
            currentTitle: nil
        ))
        let refreshCounts = await refreshImportedMedia(media, onProgress: onProgress)

        return DataImportReport(
            mediaCount: media.count,
            watchedEpisodeCount: watchedEpisodes.count,
            refreshedMediaCount: refreshCounts.media,
            refreshedScheduleCount: refreshCounts.schedules
        )
    }
}

private extension DefaultDataImportUseCase {
    struct Enrichment: Sendable {
        let item: LibraryItem
        let details: ShowDetails?
        let seasons: [ShowSeason]?
    }

    struct RefreshCounts {
        var media = 0
        var schedules = 0
    }

    func refreshImportedMedia(
        _ media: [LibraryItem],
        onProgress: @escaping @MainActor (DataImportProgress) -> Void
    ) async -> RefreshCounts {
        onProgress(DataImportProgress(
            phase: .refreshingMedia,
            completedUnitCount: 0,
            totalUnitCount: media.count,
            currentTitle: media.first?.title
        ))

        let showDetailsUseCase = showDetailsUseCase
        var counts = RefreshCounts()
        var completedUnitCount = 0

        await withTaskGroup(of: Enrichment.self) { group in
            var pendingItems = media.makeIterator()

            for _ in 0 ..< min(Self.maximumConcurrentRefreshes, media.count) {
                guard let item = pendingItems.next() else {
                    break
                }
                group.addTask {
                    await Self.enrichment(for: item, using: showDetailsUseCase)
                }
            }

            while let enrichment = await group.next() {
                if let details = enrichment.details {
                    followedMediaStore.update(with: details, for: enrichment.item.candidate)
                    counts.media += 1
                }
                if let seasons = enrichment.seasons {
                    let currentItem = followedMediaStore.item(id: enrichment.item.id) ?? enrichment.item
                    episodeScheduleStore.save(item: currentItem, seasons: seasons)
                    counts.schedules += 1
                }

                completedUnitCount += 1
                let nextItem = pendingItems.next()
                if let nextItem {
                    group.addTask {
                        await Self.enrichment(for: nextItem, using: showDetailsUseCase)
                    }
                }
                onProgress(DataImportProgress(
                    phase: .refreshingMedia,
                    completedUnitCount: completedUnitCount,
                    totalUnitCount: media.count,
                    currentTitle: nextItem?.title
                ))
            }
        }

        return counts
    }

    nonisolated static func enrichment(
        for item: LibraryItem,
        using showDetailsUseCase: any ShowDetailsUseCase
    ) async -> Enrichment {
        async let details = try? showDetailsUseCase.fetchDetails(for: item.candidate)
        async let seasons = try? showDetailsUseCase.fetchEpisodes(for: item.candidate)
        return await Enrichment(item: item, details: details, seasons: seasons)
    }
}
