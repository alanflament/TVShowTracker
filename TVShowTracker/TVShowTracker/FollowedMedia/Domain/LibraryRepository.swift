//
//  LibraryRepository.swift
//  TVShowTracker
//
//  Created by Alan Flament on 29/07/2026.
//

@MainActor
protocol LibraryRepository {
    func loadItems() throws -> [LibraryItem]
    func save(_ item: LibraryItem) throws
    func delete(id: String) throws
}
