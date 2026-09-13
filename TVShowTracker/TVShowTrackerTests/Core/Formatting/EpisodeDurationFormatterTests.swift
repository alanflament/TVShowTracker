//
//  EpisodeDurationFormatterTests.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

struct EpisodeDurationFormatterTests {
    @Test(arguments: [0, -1])
    func ignoresInvalidDurations(minutes: Int) {
        #expect(EpisodeDurationFormatter.format(minutes: minutes) == nil)
    }

    @Test(arguments: [
        (1, "1 min"),
        (59, "59 min"),
        (60, "1 hr 0 min"),
        (65, "1 hr 5 min"),
        (120, "2 hr 0 min")
    ])
    func formatsWholeMinutes(minutes: Int, expected: String) {
        #expect(EpisodeDurationFormatter.format(minutes: minutes) == expected)
    }
}
