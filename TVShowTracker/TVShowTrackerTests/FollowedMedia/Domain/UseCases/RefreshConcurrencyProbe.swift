//
//  RefreshConcurrencyProbe.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

actor RefreshConcurrencyProbe {
    private var activeRequestCount = 0
    private var maximumRequestCount = 0

    func beginRequest() {
        activeRequestCount += 1
        maximumRequestCount = max(maximumRequestCount, activeRequestCount)
    }

    func finishRequest() {
        activeRequestCount -= 1
    }

    func peakConcurrentRequests() -> Int {
        maximumRequestCount
    }
}
