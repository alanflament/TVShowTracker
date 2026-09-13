//
//  MediaStatus.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

nonisolated enum MediaStatus: String, Codable, Hashable, Sendable {
    case airing
    case finished
    case upcoming
    case cancelled
    case hiatus

    var requiresEpisodeScheduleRefresh: Bool {
        !isTerminal
    }

    var isTerminal: Bool {
        switch self {
        case .finished, .cancelled:
            true
        case .airing, .upcoming, .hiatus:
            false
        }
    }
}
