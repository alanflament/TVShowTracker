//
//  DebounceProbe.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

actor DebounceProbe {
    private(set) var durations = [Duration]()

    func record(_ duration: Duration) {
        durations.append(duration)
    }
}
