//
//  CalendarLibraryRepositoryStub.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

@MainActor
struct CalendarLibraryRepositoryStub: LibraryRepository {
    let items: [LibraryItem]

    func loadItems() throws -> [LibraryItem] {
        items
    }

    func save(_: LibraryItem) throws {}
    func delete(id _: String) throws {}
}
