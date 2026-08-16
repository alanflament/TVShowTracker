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

    func refreshSchedules(
        for items: [LibraryItem],
        onResult: @escaping @Sendable (EpisodeScheduleRefreshResult) async -> Void
    ) async -> [EpisodeScheduleRefreshResult] {
        await withTaskGroup(of: EpisodeScheduleRefreshResult.self) { group in
            var pendingItems = items.makeIterator()

            for _ in 0 ..< min(Self.maximumConcurrentRefreshes, items.count) {
                guard let item = pendingItems.next() else {
                    break
                }
                group.addTask(priority: .background) {
                    await refreshSchedule(for: item)
                }
            }

            var results = [EpisodeScheduleRefreshResult]()
            while let result = await group.next() {
                results.append(result)

                if let item = pendingItems.next() {
                    group.addTask(priority: .background) {
                        await refreshSchedule(for: item)
                    }
                }

                await onResult(result)
            }
            return results
        }
    }
}

private extension DefaultEpisodeScheduleRefreshUseCase {
    func refreshSchedule(for item: LibraryItem) async -> EpisodeScheduleRefreshResult {
        guard let snapshot = try? await showDetailsUseCase.fetchRefreshSnapshot(for: item.candidate) else {
            return EpisodeScheduleRefreshResult(
                item: item,
                seasons: nil,
                status: nil,
                details: nil
            )
        }

        return EpisodeScheduleRefreshResult(
            item: item,
            seasons: snapshot.seasons,
            status: snapshot.details.status,
            details: snapshot.details
        )
    }
}
