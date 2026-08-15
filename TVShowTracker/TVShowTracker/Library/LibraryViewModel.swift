//
//  LibraryViewModel.swift
//  TVShowTracker
//
//  Created by Alan Flament on 12/08/2026.
//

import Foundation
import Observation

@MainActor @Observable
final class LibraryViewModel {
    private let followedMediaStore: FollowedMediaStore

    var query = ""
    var category: LibraryCategory = .all {
        didSet {
            guard category != oldValue else {
                return
            }
            filter = .all
        }
    }

    var filter: LibraryFilter = .all

    init(followedMediaStore: FollowedMediaStore) {
        self.followedMediaStore = followedMediaStore
    }

    var items: [LibraryItem] {
        followedMediaStore.items
            .filter(matchesQuery)
            .filter(category.matches)
            .filter(filter.matches)
            .sorted(by: isAlphabeticallyOrdered)
    }

    var isLibraryEmpty: Bool {
        followedMediaStore.items.isEmpty
    }

    var errorMessage: String? {
        followedMediaStore.errorMessage
    }

    func count(for filter: LibraryFilter) -> Int {
        followedMediaStore.items
            .filter(category.matches)
            .count(where: filter.matches)
    }

    func count(for category: LibraryCategory) -> Int {
        followedMediaStore.items.count(where: category.matches)
    }

    func remove(_ item: LibraryItem) {
        followedMediaStore.remove(item)
    }

    func resetFilters() {
        query = ""
        category = .all
        filter = .all
    }

    private func matchesQuery(_ item: LibraryItem) -> Bool {
        let normalizedQuery = normalized(query)
        guard !normalizedQuery.isEmpty else {
            return true
        }

        return normalized(item.title).contains(normalizedQuery)
            || item.alternateTitle.map(normalized)?.contains(normalizedQuery) == true
    }

    private func isAlphabeticallyOrdered(_ lhs: LibraryItem, _ rhs: LibraryItem) -> Bool {
        lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
    }

    private func normalized(_ value: String) -> String {
        value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }
}
