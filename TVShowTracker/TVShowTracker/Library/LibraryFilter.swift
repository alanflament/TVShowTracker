//
//  LibraryFilter.swift
//  TVShowTracker
//
//  Created by Alan Flament on 12/08/2026.
//

import Foundation

enum LibraryFilter: String, CaseIterable, Identifiable {
    case all
    case watching
    case upcoming
    case finished

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .all:
            "All"
        case .watching:
            "Watching"
        case .upcoming:
            "Upcoming"
        case .finished:
            "Finished"
        }
    }

    func matches(_ item: LibraryItem) -> Bool {
        switch self {
        case .all:
            true
        case .watching:
            item.status == .airing || item.status == .hiatus
        case .upcoming:
            item.status == .upcoming
        case .finished:
            item.status == .finished || item.status == .cancelled
        }
    }
}
