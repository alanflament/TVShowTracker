//
//  MutableLibraryRepository.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import SwiftData
import Testing
@testable import TVShowTracker

@MainActor
final class MutableLibraryRepository: LibraryRepository {
    var items: [LibraryItem]
    var shouldFail = false

    init(items: [LibraryItem]) {
        self.items = items
    }

    func loadItems() throws -> [LibraryItem] {
        if shouldFail {
            throw FollowedMediaStoreTestError.failed
        }
        return items
    }

    func save(_ item: LibraryItem) throws {
        items.removeAll { $0.id == item.id }
        items.append(item)
    }

    func delete(id: String) throws {
        items.removeAll { $0.id == id }
    }
}
