//
//  FollowedMediaStore.swift
//  TVShowTracker
//
//  Created by Alan Flament on 29/07/2026.
//

import Foundation
import Observation

@MainActor @Observable
final class FollowedMediaStore {
    private let repository: any LibraryRepository

    private(set) var items: [LibraryItem] = []
    private(set) var errorMessage: String?

    init(repository: any LibraryRepository) {
        self.repository = repository
        reload()
    }

    func reload() {
        do {
            items = try repository.loadItems()
            errorMessage = nil
        } catch {
            items = []
            errorMessage = error.localizedDescription
        }
    }

    func contains(_ candidate: SearchCandidate) -> Bool {
        items.contains { $0.id == candidate.id }
    }

    func toggle(_ candidate: SearchCandidate) {
        if contains(candidate) {
            remove(id: candidate.id)
        } else {
            save(LibraryItem(candidate: candidate))
        }
    }

    func remove(_ item: LibraryItem) {
        remove(id: item.id)
    }

    func item(id: String) -> LibraryItem? {
        items.first { $0.id == id }
    }

    private func save(_ item: LibraryItem) {
        do {
            try repository.save(item)
            items.removeAll { $0.id == item.id }
            items.insert(item, at: 0)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func remove(id: String) {
        do {
            try repository.delete(id: id)
            items.removeAll { $0.id == id }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
