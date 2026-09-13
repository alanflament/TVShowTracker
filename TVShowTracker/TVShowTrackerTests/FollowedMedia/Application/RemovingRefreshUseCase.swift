//
//  RemovingRefreshUseCase.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

struct RemovingRefreshUseCase: EpisodeScheduleRefreshUseCase {
    let library: FollowedMediaStore

    func refreshSchedules(
        for items: [LibraryItem],
        onResult: @escaping @Sendable (EpisodeScheduleRefreshResult) async -> Void
    ) async -> [EpisodeScheduleRefreshResult] {
        guard let item = items.first else { return [] }
        library.remove(item)
        let result = EpisodeScheduleRefreshResult(item: item, seasons: [], status: .finished)
        await onResult(result)
        return [result]
    }
}
