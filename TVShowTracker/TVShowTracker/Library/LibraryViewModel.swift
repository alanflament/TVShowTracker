//
//  LibraryViewModel.swift
//  TVShowTracker
//

import Foundation
import Observation

@MainActor @Observable
final class LibraryViewModel {
    private let followedMediaStore: FollowedMediaStore

    var query = ""
    var filter: LibraryFilter = .all

    init(followedMediaStore: FollowedMediaStore) {
        self.followedMediaStore = followedMediaStore
    }

    var items: [LibraryItem] {
        followedMediaStore.items
            .filter(matchesQuery)
            .filter(filter.matches)
            .sorted(by: isAlphabeticallyOrdered)
    }

    var isLibraryEmpty: Bool {
        followedMediaStore.items.isEmpty
    }

    var isFiltering: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var errorMessage: String? {
        followedMediaStore.errorMessage
    }

    func remove(_ item: LibraryItem) {
        followedMediaStore.remove(item)
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
