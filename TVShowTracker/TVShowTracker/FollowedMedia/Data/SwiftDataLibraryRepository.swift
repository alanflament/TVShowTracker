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
        let existing = try modelContext.fetch(FetchDescriptor<LibraryItemModel>())
            .first { $0.id == item.id }

        if let existing {
            try existing.update(with: item, encoder: encoder)
        } else {
            try modelContext.insert(LibraryItemModel(item: item, encoder: encoder))
        }

        try modelContext.save()
    }

    func delete(id: String) throws {
        let items = try modelContext.fetch(FetchDescriptor<LibraryItemModel>())
        if let item = items.first(where: { $0.id == id }) {
            modelContext.delete(item)
            try modelContext.save()
        }
    }
}
