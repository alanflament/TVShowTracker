//
//  SwiftDataLibraryRepositoryTests.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import SwiftData
import Testing
@testable import TVShowTracker

@MainActor
struct SwiftDataLibraryRepositoryTests {
    @Test func swiftDataLibraryRepositoryPersistsAndDeletesItems() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: LibraryItemModel.self,
            configurations: configuration
        )
        let repository = SwiftDataLibraryRepository(modelContext: container.mainContext)
        let candidate = MediaCandidate.tvShow(id: 42, title: "The Bear")

        try repository.save(LibraryItem(candidate: candidate))
        let savedItems = try repository.loadItems()

        #expect(savedItems.map(\.id) == [candidate.id])
        #expect(savedItems.first?.candidate == candidate)

        try repository.delete(id: candidate.id)

        #expect(try repository.loadItems().isEmpty)
    }

    @Test func legacyLibraryItemDefaultsToWatching() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: LibraryItemModel.self,
            configurations: configuration
        )
        let model = try LibraryItemModel(
            id: "tmdb:42",
            providerRawValue: MediaProvider.tmdb.rawValue,
            providerID: 42,
            kindRawValue: MediaKind.tvShow.rawValue,
            title: "The Bear",
            alternateTitle: nil,
            posterURLString: nil,
            releaseYear: nil,
            totalEpisodeCount: nil,
            statusRawValue: MediaStatus.finished.rawValue,
            nextEpisodeNumber: nil,
            nextEpisodeAirDate: nil,
            animeInstallmentsData: JSONEncoder().encode([AnimeInstallmentReference]()),
            addedAt: .now
        )
        container.mainContext.insert(model)
        try container.mainContext.save()

        let items = try SwiftDataLibraryRepository(modelContext: container.mainContext).loadItems()

        #expect(items.first?.trackingStatus == .watching)
    }
}
