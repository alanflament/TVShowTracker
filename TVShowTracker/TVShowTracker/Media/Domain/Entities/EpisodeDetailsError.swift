//
//  EpisodeDetailsError.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/08/2026.
//

import Foundation

nonisolated enum EpisodeDetailsError: LocalizedError {
    case notFound

    var errorDescription: String? {
        switch self {
        case .notFound:
            "Episode details could not be found."
        }
    }
}
