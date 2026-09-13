//
//  CalendarUndatedMedia.swift
//  TVShowTracker
//
//  Created by Alan Flament on 12/08/2026.
//

import Foundation

nonisolated struct CalendarUndatedMedia: Hashable, Sendable {
    let candidate: MediaCandidate
    let showTitle: String
    let posterURL: URL?

    init(item: LibraryItem) {
        candidate = item.candidate
        showTitle = item.title
        posterURL = item.posterURL
    }
}
