//
//  DefaultNextEpisodeUseCase.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

@MainActor
struct DefaultNextEpisodeUseCase: NextEpisodeUseCase {
    private let episodeScheduleStore: EpisodeScheduleStore

    init(episodeScheduleStore: EpisodeScheduleStore) {
        self.episodeScheduleStore = episodeScheduleStore
    }

    func findNextEpisode(
        in items: [LibraryItem],
        watchedEpisodeIDs: Set<String>,
        now: Date
    ) async -> NextEpisodeResult {
        let missingScheduleCount = items.count { episodeScheduleStore.schedule(for: $0) == nil }
        return NextEpisodeResult(
            episodes: items.compactMap { item in
                nextEpisode(for: item, watchedEpisodeIDs: watchedEpisodeIDs, now: now)
            }.sorted { lhs, rhs in
                alphabeticalShowOrder(lhs, rhs)
            },
            missingScheduleCount: missingScheduleCount
        )
    }
}

private extension DefaultNextEpisodeUseCase {
    func nextEpisode(
        for item: LibraryItem,
        watchedEpisodeIDs: Set<String>,
        now: Date
    ) -> CalendarEpisode? {
        let episodes = (episodeScheduleStore.schedule(for: item)?.seasons ?? [])
            .filter { !$0.isSpecial }
            .flatMap(\.episodes)
            .map { CalendarEpisode(item: item, episode: $0) }
            .filter { !watchedEpisodeIDs.contains($0.episode.id) }

        let releasedEpisodes = episodes.filter { $0.episode.isReleased(at: now) }
        if let nextReleasedEpisode = releasedEpisodes.min(by: expectedEpisodeOrder) {
            return nextReleasedEpisode
        }

        return episodes.filter {
            guard let airDate = $0.episode.airDate else {
                return false
            }
            return airDate > now
        }.min(by: upcomingEpisodeOrder)
    }

    func alphabeticalShowOrder(_ lhs: CalendarEpisode, _ rhs: CalendarEpisode) -> Bool {
        let titleOrder = lhs.showTitle.localizedCaseInsensitiveCompare(rhs.showTitle)
        return titleOrder == .orderedSame
            ? lhs.episode.id < rhs.episode.id
            : titleOrder == .orderedAscending
    }

    func expectedEpisodeOrder(_ lhs: CalendarEpisode, _ rhs: CalendarEpisode) -> Bool {
        let lhsIndex = (lhs.episode.seasonNumber, lhs.episode.number)
        let rhsIndex = (rhs.episode.seasonNumber, rhs.episode.number)
        return lhsIndex == rhsIndex
            ? lhs.episode.id < rhs.episode.id
            : lhsIndex < rhsIndex
    }

    func upcomingEpisodeOrder(_ lhs: CalendarEpisode, _ rhs: CalendarEpisode) -> Bool {
        guard let lhsDate = lhs.episode.airDate,
              let rhsDate = rhs.episode.airDate
        else {
            return expectedEpisodeOrder(lhs, rhs)
        }
        return lhsDate == rhsDate
            ? expectedEpisodeOrder(lhs, rhs)
            : lhsDate < rhsDate
    }
}
