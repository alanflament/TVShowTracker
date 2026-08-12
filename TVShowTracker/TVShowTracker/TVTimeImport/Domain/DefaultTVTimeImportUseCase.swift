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
        try await loadEpisodeSchedules(
            for: resolution.shows,
            onProgress: onProgress
        )
        let report = try restoreEpisodes(
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
        var report = MutableReport(parsedWatchedEpisodeCount: export.watchedEpisodes.count)
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

    func loadEpisodeSchedules(
        for resolvedShows: [ResolvedShow],
        onProgress: @escaping @MainActor (TVTimeImportProgress) -> Void
    ) async throws {
        for (index, resolvedShow) in resolvedShows.enumerated() {
            try Task.checkCancellation()
            onProgress(TVTimeImportProgress(
                phase: .loadingEpisodeSchedules,
                completedUnitCount: index,
                totalUnitCount: resolvedShows.count,
                currentTitle: resolvedShow.candidate.title
            ))
            try await loadEpisodeSchedule(for: resolvedShow)
        }

        onProgress(TVTimeImportProgress(
            phase: .loadingEpisodeSchedules,
            completedUnitCount: resolvedShows.count,
            totalUnitCount: resolvedShows.count,
            currentTitle: nil
        ))
    }

    func loadEpisodeSchedule(
        for resolvedShow: ResolvedShow
    ) async throws {
        guard let item = followedMediaStore.item(id: resolvedShow.candidate.id),
              episodeScheduleStore.schedule(for: item) == nil
        else {
            return
        }

        do {
            let seasons = try await showDetailsUseCase.fetchEpisodes(for: resolvedShow.candidate)
            episodeScheduleStore.save(item: item, seasons: seasons)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            return
        }
    }

    func restoreEpisodes(
        for resolvedShows: [ResolvedShow],
        initialReport: MutableReport,
        onProgress: @escaping @MainActor (TVTimeImportProgress) -> Void
    ) throws -> MutableReport {
        var report = initialReport

        for (index, resolvedShow) in resolvedShows.enumerated() {
            try Task.checkCancellation()
            onProgress(TVTimeImportProgress(
                phase: .restoringWatchedEpisodes,
                completedUnitCount: index,
                totalUnitCount: resolvedShows.count,
                currentTitle: resolvedShow.candidate.title
            ))

            guard let item = followedMediaStore.item(id: resolvedShow.candidate.id),
                  let schedule = episodeScheduleStore.schedule(for: item)
            else {
                report.unresolvedEpisodeCount += resolvedShow.watchedEpisodes.count
                continue
            }
            let result = try restore(
                watchedEpisodes: resolvedShow.watchedEpisodes,
                using: episodesByNumber(in: schedule.seasons)
            )
            report.restoredEpisodeCount += result.restoredEpisodeCount
            report.unresolvedEpisodeCount += result.unresolvedEpisodeCount
        }

        onProgress(TVTimeImportProgress(
            phase: .restoringWatchedEpisodes,
            completedUnitCount: resolvedShows.count,
            totalUnitCount: resolvedShows.count,
            currentTitle: nil
        ))
        return report
    }

    func episodesByNumber(in seasons: [ShowSeason]) -> [EpisodeNumber: ShowEpisode] {
        Dictionary(uniqueKeysWithValues: seasons.flatMap(\.episodes).map {
            (EpisodeNumber(season: $0.seasonNumber, episode: $0.number), $0)
        })
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
        let parsedWatchedEpisodeCount: Int
        var restoredEpisodeCount = 0
        var unresolvedShowTitles = Set<String>()
        var unresolvedEpisodeCount = 0

        var asDomain: TVTimeImportReport {
            TVTimeImportReport(
                addedShowCount: addedShowCount,
                existingShowCount: existingShowCount,
                parsedWatchedEpisodeCount: parsedWatchedEpisodeCount,
                restoredEpisodeCount: restoredEpisodeCount,
                unresolvedShowTitles: unresolvedShowTitles.sorted(),
                unresolvedEpisodeCount: unresolvedEpisodeCount
            )
        }
    }
}
