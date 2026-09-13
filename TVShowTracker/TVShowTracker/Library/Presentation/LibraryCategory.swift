//
//  LibraryCategory.swift
//  TVShowTracker
//
//  Created by Alan Flament on 15/08/2026.
//

enum LibraryCategory: String, CaseIterable, Identifiable {
    case all
    case active
    case planned
    case history

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .all:
            "All"
        case .active:
            "Active"
        case .planned:
            "Planned"
        case .history:
            "History"
        }
    }

    var secondaryFilters: [LibraryFilter] {
        switch self {
        case .active:
            [.all, .watching, .paused]
        case .history:
            [.all, .completed, .dropped]
        case .all, .planned:
            []
        }
    }

    func matches(_ item: LibraryItem) -> Bool {
        switch self {
        case .all:
            true
        case .active:
            item.trackingStatus == .watching || item.trackingStatus == .paused
        case .planned:
            item.trackingStatus == .planToWatch
        case .history:
            item.trackingStatus == .completed || item.trackingStatus == .dropped
        }
    }
}
