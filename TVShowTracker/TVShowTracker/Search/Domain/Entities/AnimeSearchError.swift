//
//  AnimeSearchError.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

nonisolated struct AnimeSearchError: LocalizedError, Sendable {
    let providerErrors: [MediaProvider: String]

    var errorDescription: String? {
        "All anime search sources are unavailable."
    }
}
