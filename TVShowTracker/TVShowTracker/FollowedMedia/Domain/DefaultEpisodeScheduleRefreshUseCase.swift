//
//  DefaultEpisodeScheduleRefreshUseCase.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

struct DefaultEpisodeScheduleRefreshUseCase: EpisodeScheduleRefreshUseCase {
    private static let maximumConcurrentRefreshes = 4
    private let showDetailsUseCase: any ShowDetailsUseCase

    init(showDetailsUseCase: any ShowDetailsUseCase) {
        self.showDetailsUseCase = showDetailsUseCase
    }

    func refreshSchedules(for items: [LibraryItem]) async -> [EpisodeScheduleRefreshResult] {
        await withTaskGroup(of: EpisodeScheduleRefreshResult.self) { group in
            var pendingItems = items.makeIterator()

            for _ in 0 ..< min(Self.maximumConcurrentRefreshes, items.count) {
                guard let item = pendingItems.next() else {
                    break
                }
                group.addTask {
                    await refreshSchedule(for: item)
                }
            }

            var results = [EpisodeScheduleRefreshResult]()
            while let result = await group.next() {
                results.append(result)

                if let item = pendingItems.next() {
                    group.addTask {
                        await refreshSchedule(for: item)
                    }
                }
            }
            return results
        }
    }
}

private extension DefaultEpisodeScheduleRefreshUseCase {
    func refreshSchedule(for item: LibraryItem) async -> EpisodeScheduleRefreshResult {
        guard item.status == nil else {
            return await refreshScheduleWithoutStatusLookup(for: item)
        }

        async let details = showDetailsUseCase.fetchDetails(for: item.candidate)
        async let seasons = showDetailsUseCase.fetchEpisodes(for: item.candidate)

        return EpisodeScheduleRefreshResult(
            item: item,
            seasons: try? await seasons,
            status: (try? await details)?.status
        )
    }

    func refreshScheduleWithoutStatusLookup(for item: LibraryItem) async -> EpisodeScheduleRefreshResult {
        EpisodeScheduleRefreshResult(
            item: item,
            seasons: try? await showDetailsUseCase.fetchEpisodes(for: item.candidate),
            status: nil
        )
    }
}
