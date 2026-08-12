//
//  CalendarUndatedMedia.swift
//  TVShowTracker
//
//  Created by Alan Flament on 12/08/2026.
//

import Foundation

struct CalendarUndatedMedia: Hashable, Sendable {
    let candidate: SearchCandidate
    let showTitle: String
    let posterURL: URL?

    init(item: LibraryItem) {
        candidate = item.candidate
        showTitle = item.title
        posterURL = item.posterURL
    }
}
