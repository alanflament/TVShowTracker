//
//  LibraryFilter.swift
//  TVShowTracker
//
//  Created by Alan Flament on 12/08/2026.
//

import Foundation

enum LibraryFilter: String, CaseIterable, Identifiable {
    case all
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
        case .all:
            "All"
        case .planToWatch:
            TrackingStatus.planToWatch.title
        case .watching:
            TrackingStatus.watching.title
        case .paused:
            TrackingStatus.paused.title
        case .completed:
            TrackingStatus.completed.title
        case .dropped:
            TrackingStatus.dropped.title
        }
    }

    func matches(_ item: LibraryItem) -> Bool {
        switch self {
        case .all:
            true
        case .planToWatch:
            item.trackingStatus == .planToWatch
        case .watching:
            item.trackingStatus == .watching
        case .paused:
            item.trackingStatus == .paused
        case .completed:
            item.trackingStatus == .completed
        case .dropped:
            item.trackingStatus == .dropped
        }
    }
}
