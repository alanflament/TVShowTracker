//
//  DebounceGate.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

actor DebounceGate {
    private(set) var duration: Duration?
    private var continuation: CheckedContinuation<Void, Never>?

    var isWaiting: Bool {
        continuation != nil
    }

    func wait(for duration: Duration) async throws {
        self.duration = duration
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
        try Task.checkCancellation()
    }

    func resume() {
        continuation?.resume()
        continuation = nil
    }
}
