//
//  TrackingStatus.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/08/2026.
//

enum TrackingStatus: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case planToWatch
    case watching
    case paused
    case completed
    case dropped

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .planToWatch:
            "Plan to Watch"
        case .watching:
            "Watching"
        case .paused:
            "Paused"
        case .completed:
            "Completed"
        case .dropped:
            "Dropped"
        }
    }

    var systemImage: String {
        switch self {
        case .planToWatch:
            "bookmark"
        case .watching:
            "play.circle"
        case .paused:
            "pause.circle"
        case .completed:
            "flag.checkered"
        case .dropped:
            "xmark.circle"
        }
    }

    var appearsInUpNext: Bool {
        self == .watching
    }
}
