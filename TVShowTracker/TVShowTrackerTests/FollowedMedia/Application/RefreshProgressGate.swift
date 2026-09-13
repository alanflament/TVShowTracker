//
//  RefreshProgressGate.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

actor RefreshProgressGate {
    private var isReleased = false
    private var continuation: CheckedContinuation<Void, Never>?

    func waitForRelease() async {
        guard !isReleased else {
            return
        }

        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func release() {
        isReleased = true
        continuation?.resume()
        continuation = nil
    }
}
