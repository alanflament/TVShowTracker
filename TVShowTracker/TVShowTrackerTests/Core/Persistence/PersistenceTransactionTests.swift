//
//  PersistenceTransactionTests.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import SwiftData
import Testing
@testable import TVShowTracker

@MainActor
struct PersistenceTransactionTests {
    @Test func failedMutationCannotLeakIntoTheNextSave() throws {
        let container = try ModelContainer(
            for: WatchedEpisodeModel.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let repository = SwiftDataEpisodeWatchRepository(modelContext: context)
        let original = WatchedEpisode(id: "tmdb:1:1:1", watchedAt: Date(timeIntervalSince1970: 100))
        try repository.save(original)
        let stored = try #require(context.fetch(FetchDescriptor<WatchedEpisodeModel>()).first)

        #expect(throws: PersistenceMutationTestError.failed) {
            try context.saveChanges {
                stored.watchedAt = Date(timeIntervalSince1970: 200)
                context.insert(WatchedEpisodeModel(episode: WatchedEpisode(id: "tmdb:1:1:2", watchedAt: .now)))
                throw PersistenceMutationTestError.failed
            }
        }
        try repository.save(WatchedEpisode(id: "tmdb:1:1:3", watchedAt: .now))
        let records = try repository.loadWatchedEpisodes()
        #expect(records.first { $0.id == original.id } == original)
        #expect(!records.contains { $0.id == "tmdb:1:1:2" })
        #expect(records.count == 2)
    }
}
