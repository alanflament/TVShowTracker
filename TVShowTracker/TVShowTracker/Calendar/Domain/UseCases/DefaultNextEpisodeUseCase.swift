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
        let episodes = items.flatMap { item in
            (episodeScheduleStore.schedule(for: item)?.seasons ?? []).flatMap(\.episodes).map {
                CalendarEpisode(item: item, episode: $0)
            }
        }.filter { !watchedEpisodeIDs.contains($0.episode.id) }

        let releasedEpisodes = episodes.filter { $0.episode.isReleased(at: now) }
        if let nextReleasedEpisode = releasedEpisodes.min(by: releasedEpisodeOrder) {
            return NextEpisodeResult(
                episode: nextReleasedEpisode,
                missingScheduleCount: missingScheduleCount
            )
        }

        let futureEpisodes = episodes.filter {
            guard let airDate = $0.episode.airDate else {
                return false
            }
            return airDate > now
        }
        return NextEpisodeResult(
            episode: futureEpisodes.min(by: futureEpisodeOrder),
            missingScheduleCount: missingScheduleCount
        )
    }
}

private extension DefaultNextEpisodeUseCase {
    func releasedEpisodeOrder(_ lhs: CalendarEpisode, _ rhs: CalendarEpisode) -> Bool {
        let lhsDate = lhs.episode.airDate ?? .distantPast
        let rhsDate = rhs.episode.airDate ?? .distantPast
        return (lhsDate, lhs.episode.id) < (rhsDate, rhs.episode.id)
    }

    func futureEpisodeOrder(_ lhs: CalendarEpisode, _ rhs: CalendarEpisode) -> Bool {
        guard let lhsDate = lhs.episode.airDate,
              let rhsDate = rhs.episode.airDate
        else {
            return false
        }
        return (lhsDate, lhs.episode.id) < (rhsDate, rhs.episode.id)
    }
}
