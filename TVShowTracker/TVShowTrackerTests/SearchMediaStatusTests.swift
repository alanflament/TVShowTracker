//
//  SearchMediaStatusTests.swift
//  TVShowTrackerTests
//
//  Created by Alan Flament on 11/08/2026.
//

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
}
