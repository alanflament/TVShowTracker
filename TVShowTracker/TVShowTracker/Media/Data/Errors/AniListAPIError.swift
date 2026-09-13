//
//  AniListAPIError.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

enum AniListAPIError: LocalizedError, Sendable {
    case queryFailed(String)

    var errorDescription: String? {
        switch self {
        case let .queryFailed(message):
            message
        }
    }
}
