//
//  DefaultTVTimeImportUseCase.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

@MainActor
final class DefaultTVTimeImportUseCase: TVTimeImportUseCase {
    private let exportParser: any TVTimeExportParsing
    private let searchCatalogUseCase: any SearchCatalogUseCase
    private let showDetailsUseCase: any ShowDetailsUseCase
    private let followedMediaStore: FollowedMediaStore
    private let episodeWatchStore: EpisodeWatchStore
    private let episodeScheduleStore: EpisodeScheduleStore
    private let candidateMatcher: TVTimeSearchCandidateMatcher

    init(
        exportParser: any TVTimeExportParsing,
        searchCatalogUseCase: any SearchCatalogUseCase,
        showDetailsUseCase: any ShowDetailsUseCase,
        followedMediaStore: FollowedMediaStore,
        episodeWatchStore: EpisodeWatchStore,
        episodeScheduleStore: EpisodeScheduleStore,
        candidateMatcher: TVTimeSearchCandidateMatcher
    ) {
        self.exportParser = exportParser
        self.searchCatalogUseCase = searchCatalogUseCase
        self.showDetailsUseCase = showDetailsUseCase
        self.followedMediaStore = followedMediaStore
        self.episodeWatchStore = episodeWatchStore
        self.episodeScheduleStore = episodeScheduleStore
        self.candidateMatcher = candidateMatcher
    }

    func importExport(
        at folderURL: URL,
        onProgress: @escaping @MainActor (TVTimeImportProgress) -> Void
    ) async throws -> TVTimeImportReport {
        onProgress(TVTimeImportProgress(
            phase: .readingExport,
            completedUnitCount: 0,
            totalUnitCount: 1,
            currentTitle: nil
        ))
        let export = try exportParser.parseExport(at: folderURL)
        let resolution = try await resolveShows(in: export, onProgress: onProgress)
        let report = try await restoreSchedulesAndEpisodes(
            for: resolution.shows,
            initialReport: resolution.report,
            onProgress: onProgress
        )
        return report.asDomain
    }
}

private extension DefaultTVTimeImportUseCase {
    struct EpisodeNumber: Hashable {
        let season: Int
        let episode: Int
    }

    struct ResolvedShow {
        let candidate: SearchCandidate
        let watchedEpisodes: [TVTimeWatchedEpisode]
    }

    struct Resolution {
        let shows: [ResolvedShow]
        let report: MutableReport
    }

    func resolveShows(
        in export: TVTimeExport,
        onProgress: @escaping @MainActor (TVTimeImportProgress) -> Void
    ) async throws -> Resolution {
        let watchedEpisodesByShow = Dictionary(grouping: export.watchedEpisodes, by: \.normalizedShowTitle)
        var report = MutableReport()
        var resolvedShows = [ResolvedShow]()

        for (index, show) in export.shows.enumerated() {
            try Task.checkCancellation()
            onProgress(TVTimeImportProgress(
                phase: .resolvingShows,
                completedUnitCount: index,
                totalUnitCount: export.shows.count,
                currentTitle: show.title
            ))
            let catalog = await searchCatalogUseCase.search(matching: show.title)

            guard let candidate = candidateMatcher.match(show, in: catalog) else {
                report.unresolvedShowTitles.insert(show.title)
                report.unresolvedEpisodeCount += watchedEpisodesByShow[show.normalizedTitle]?.count ?? 0
                continue
            }

            if followedMediaStore.contains(candidate) {
                report.existingShowCount += 1
            } else {
                followedMediaStore.addIfMissing(candidate)
                report.addedShowCount += 1
            }
            resolvedShows.append(ResolvedShow(
                candidate: candidate,
                watchedEpisodes: watchedEpisodesByShow[show.normalizedTitle] ?? []
            ))
        }

        return Resolution(shows: resolvedShows, report: report)
    }

    func restoreSchedulesAndEpisodes(
        for resolvedShows: [ResolvedShow],
        initialReport: MutableReport,
        onProgress: @escaping @MainActor (TVTimeImportProgress) -> Void
    ) async throws -> MutableReport {
        var report = initialReport
        var completedShowCount = 0

        for resolvedShow in resolvedShows {
            try Task.checkCancellation()
            onProgress(TVTimeImportProgress(
                phase: .loadingEpisodeSchedules,
                completedUnitCount: completedShowCount,
                totalUnitCount: resolvedShows.count,
                currentTitle: resolvedShow.candidate.title
            ))
            let result = try await restoreScheduleAndEpisodes(for: resolvedShow)
            completedShowCount += 1
            report.restoredEpisodeCount += result.restoredEpisodeCount
            report.unresolvedEpisodeCount += result.unresolvedEpisodeCount
        }

        onProgress(TVTimeImportProgress(
            phase: .loadingEpisodeSchedules,
            completedUnitCount: resolvedShows.count,
            totalUnitCount: resolvedShows.count,
            currentTitle: nil
        ))
        return report
    }

    func restoreScheduleAndEpisodes(
        for resolvedShow: ResolvedShow
    ) async throws -> EpisodeRestorationResult {
        do {
            let seasons = try await showDetailsUseCase.fetchEpisodes(for: resolvedShow.candidate)
            guard let item = followedMediaStore.item(id: resolvedShow.candidate.id) else {
                return EpisodeRestorationResult(
                    restoredEpisodeCount: 0,
                    unresolvedEpisodeCount: resolvedShow.watchedEpisodes.count
                )
            }
            episodeScheduleStore.save(item: item, seasons: seasons)
            let episodesByNumber = Dictionary(uniqueKeysWithValues: seasons.flatMap(\.episodes).map {
                (EpisodeNumber(season: $0.seasonNumber, episode: $0.number), $0)
            })
            return try restore(
                watchedEpisodes: resolvedShow.watchedEpisodes,
                using: episodesByNumber
            )
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            return EpisodeRestorationResult(
                restoredEpisodeCount: 0,
                unresolvedEpisodeCount: resolvedShow.watchedEpisodes.count
            )
        }
    }

    func restore(
        watchedEpisodes: [TVTimeWatchedEpisode],
        using episodesByNumber: [EpisodeNumber: ShowEpisode]
    ) throws -> EpisodeRestorationResult {
        var restoredEpisodeCount = 0
        var unresolvedEpisodeCount = 0

        for watchedEpisode in watchedEpisodes {
            try Task.checkCancellation()
            let key = EpisodeNumber(
                season: watchedEpisode.seasonNumber,
                episode: watchedEpisode.episodeNumber
            )
            guard let episode = episodesByNumber[key] else {
                unresolvedEpisodeCount += 1
                continue
            }

            if !episodeWatchStore.isWatched(episode) {
                episodeWatchStore.markWatched(episode, watchedAt: watchedEpisode.watchedAt)
                restoredEpisodeCount += 1
            }
        }
        return EpisodeRestorationResult(
            restoredEpisodeCount: restoredEpisodeCount,
            unresolvedEpisodeCount: unresolvedEpisodeCount
        )
    }

    struct EpisodeRestorationResult {
        let restoredEpisodeCount: Int
        let unresolvedEpisodeCount: Int
    }

    struct MutableReport {
        var addedShowCount = 0
        var existingShowCount = 0
        var restoredEpisodeCount = 0
        var unresolvedShowTitles = Set<String>()
        var unresolvedEpisodeCount = 0

        var asDomain: TVTimeImportReport {
            TVTimeImportReport(
                addedShowCount: addedShowCount,
                existingShowCount: existingShowCount,
                restoredEpisodeCount: restoredEpisodeCount,
                unresolvedShowTitles: unresolvedShowTitles.sorted(),
                unresolvedEpisodeCount: unresolvedEpisodeCount
            )
        }
    }
}
