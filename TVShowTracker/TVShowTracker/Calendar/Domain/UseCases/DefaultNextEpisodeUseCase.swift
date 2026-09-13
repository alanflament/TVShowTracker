//
//  DefaultNextEpisodeUseCase.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

@MainActor
struct DefaultNextEpisodeUseCase: NextEpisodeUseCase {
    private let episodeScheduleReader: any EpisodeScheduleReading

    init(episodeScheduleReader: any EpisodeScheduleReading) {
        self.episodeScheduleReader = episodeScheduleReader
    }

    func hasNextEpisode(
        in items: [LibraryItem],
        watchedEpisodeIDs: Set<String>,
        now: Date
    ) -> Bool {
        items
            .filter { $0.trackingStatus.appearsInUpNext }
            .contains { item in
                nextEpisode(for: item, watchedEpisodeIDs: watchedEpisodeIDs, now: now) != nil
            }
    }

    func findNextEpisode(
        in items: [LibraryItem],
        watchedEpisodeIDs: Set<String>,
        now: Date
    ) async -> NextEpisodeResult {
        let activeItems = items.filter { $0.trackingStatus.appearsInUpNext }
        let episodes = activeItems.compactMap { item in
            nextEpisode(for: item, watchedEpisodeIDs: watchedEpisodeIDs, now: now)
        }.sorted { lhs, rhs in
            alphabeticalShowOrder(lhs, rhs)
        }
        let episodeMediaIDs = Set(episodes.map(\.candidate.id))
        let availableEpisodeCount = activeItems.reduce(into: 0) { count, item in
            count += (episodeScheduleReader.schedule(for: item)?.seasons ?? [])
                .filter { !$0.isSpecial }
                .flatMap(\.episodes)
                .count { episode in
                    !watchedEpisodeIDs.contains(episode.id) && episode.isReleased(at: now)
                }
        }

        return NextEpisodeResult(
            episodes: episodes,
            availableEpisodeCount: availableEpisodeCount,
            undatedMedia: activeItems
                .filter { item in
                    item.requiresEpisodeScheduleRefresh
                        && item.nextEpisodeAirDate == nil
                        && !episodeMediaIDs.contains(item.id)
                }
                .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
                .map(CalendarUndatedMedia.init)
        )
    }
}

private extension DefaultNextEpisodeUseCase {
    func nextEpisode(
        for item: LibraryItem,
        watchedEpisodeIDs: Set<String>,
        now: Date
    ) -> CalendarEpisode? {
        let episodes = (episodeScheduleReader.schedule(for: item)?.seasons ?? [])
            .filter { !$0.isSpecial }
            .flatMap(\.episodes)
            .map { CalendarEpisode(item: item, episode: $0) }
            .filter { !watchedEpisodeIDs.contains($0.episode.id) }

        let releasedEpisodes = episodes.filter { $0.episode.isReleased(at: now) }
        if let nextReleasedEpisode = releasedEpisodes.min(by: expectedEpisodeOrder) {
            return CalendarEpisode(
                item: item,
                episode: nextReleasedEpisode.episode,
                additionalAvailableEpisodeCount: max(0, releasedEpisodes.count - 1)
            )
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
