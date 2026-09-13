//
//  MediaStatusTests.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

struct MediaStatusTests {
    @Test func onlyTerminalMediaStatusesSkipEpisodeScheduleRefresh() {
        #expect(!MediaStatus.finished.requiresEpisodeScheduleRefresh)
        #expect(!MediaStatus.cancelled.requiresEpisodeScheduleRefresh)
        #expect(MediaStatus.airing.requiresEpisodeScheduleRefresh)
        #expect(MediaStatus.upcoming.requiresEpisodeScheduleRefresh)
        #expect(MediaStatus.hiatus.requiresEpisodeScheduleRefresh)
    }
}
