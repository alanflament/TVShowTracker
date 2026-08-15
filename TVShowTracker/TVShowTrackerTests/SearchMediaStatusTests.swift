//
//  SearchMediaStatusTests.swift
//  TVShowTrackerTests
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

struct SearchMediaStatusTests {
    @Test func onlyTerminalMediaStatusesSkipEpisodeScheduleRefresh() {
        #expect(!SearchMediaStatus.finished.requiresEpisodeScheduleRefresh)
        #expect(!SearchMediaStatus.cancelled.requiresEpisodeScheduleRefresh)
        #expect(SearchMediaStatus.airing.requiresEpisodeScheduleRefresh)
        #expect(SearchMediaStatus.upcoming.requiresEpisodeScheduleRefresh)
        #expect(SearchMediaStatus.hiatus.requiresEpisodeScheduleRefresh)
    }

    @Test func terminalMediaUsesAMonthlyLifecycleCheckUnlessForced() {
        let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let candidate = SearchCandidate(
            provider: .tmdb,
            providerID: 1,
            kind: .tvShow,
            title: "Finished show",
            alternateTitle: nil,
            posterURL: nil,
            releaseYear: nil,
            totalEpisodeCount: nil,
            status: .finished,
            nextEpisodeNumber: nil,
            nextEpisodeAirDate: nil
        )
        let recentlyChecked = LibraryItem(
            candidate: candidate,
            lastLifecycleCheckAt: now.addingTimeInterval(-29 * 24 * 60 * 60)
        )
        let overdue = LibraryItem(
            candidate: candidate,
            lastLifecycleCheckAt: now.addingTimeInterval(-30 * 24 * 60 * 60)
        )

        #expect(!recentlyChecked.requiresProviderRefresh(at: now, force: false))
        #expect(recentlyChecked.requiresProviderRefresh(at: now, force: true))
        #expect(overdue.requiresProviderRefresh(at: now, force: false))
    }
}
