//
//  SwiftDataLibraryRepository.swift
//  TVShowTracker
//
//  Created by Alan Flament on 29/07/2026.
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataLibraryRepository: LibraryRepository {
    private let modelContext: ModelContext
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadItems() throws -> [LibraryItem] {
        let descriptor = FetchDescriptor<LibraryItemModel>(
            sortBy: [SortDescriptor(\LibraryItemModel.addedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { try $0.asDomain(decoder: decoder) }
    }

    func save(_ item: LibraryItem) throws {
        try modelContext.saveChanges {
            let itemID = item.id
            var descriptor = FetchDescriptor<LibraryItemModel>(predicate: #Predicate { $0.id == itemID })
            descriptor.fetchLimit = 1
            let existing = try modelContext.fetch(descriptor).first

            if let existing {
                try existing.update(with: item, encoder: encoder)
            } else {
                try modelContext.insert(LibraryItemModel(item: item, encoder: encoder))
            }
        }
    }

    func delete(id: String) throws {
        try modelContext.saveChanges {
            var descriptor = FetchDescriptor<LibraryItemModel>(predicate: #Predicate { $0.id == id })
            descriptor.fetchLimit = 1
            if let item = try modelContext.fetch(descriptor).first {
                modelContext.delete(item)
            }
        }
    }
}
