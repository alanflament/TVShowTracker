//
//  Error+Cancellation.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

extension Error {
    nonisolated func rethrowIfCancellation() throws {
        try Task.checkCancellation()
        if self is CancellationError {
            throw self
        }
    }
}
