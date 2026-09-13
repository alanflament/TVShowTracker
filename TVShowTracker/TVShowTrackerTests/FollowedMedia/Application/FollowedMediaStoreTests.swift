//
//  FollowedMediaStoreTests.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import SwiftData
import Testing
@testable import TVShowTracker

@MainActor
struct FollowedMediaStoreTests {
    @Test func failedReloadKeepsPreviouslyLoadedLibrary() {
        let repository = MutableLibraryRepository(items: [item()])
        let store = FollowedMediaStore(repository: repository)
        let loaded = store.items
        repository.shouldFail = true

        store.reload()

        #expect(store.items == loaded)
        #expect(store.errorMessage != nil)
    }

    @Test func updatingWithAnOldSnapshotPreservesNewerChanges() throws {
        let original = item()
        let store = FollowedMediaStore(repository: MutableLibraryRepository(items: [original]))
        store.updateStatus(.finished, for: original)
        store.updateTrackingStatus(.paused, for: original)
        let updated = try #require(store.items.first)

        #expect(updated.status == .finished)
        #expect(updated.trackingStatus == .paused)
        #expect(updated.addedAt == original.addedAt)

        store.remove(updated)
        store.updateStatus(.airing, for: original)
        store.updateTrackingStatus(.watching, for: original)
        store.recordLifecycleCheck(for: original)
        #expect(store.items.isEmpty)
    }

    private func item() -> LibraryItem {
        LibraryItem(candidate: MediaCandidate(
            provider: .tmdb, providerID: 42, kind: .tvShow, title: "A show",
            alternateTitle: nil, posterURL: nil, releaseYear: nil,
            totalEpisodeCount: nil, status: .airing,
            nextEpisodeNumber: nil, nextEpisodeAirDate: nil
        ))
    }

    @Test func preservesTrackingStatusWhenProviderDetailsAreUpdated() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: LibraryItemModel.self,
            configurations: configuration
        )
        let store = FollowedMediaStore(
            repository: SwiftDataLibraryRepository(modelContext: container.mainContext)
        )
        let searchCandidate = candidate(id: 1, title: "Dark", status: .finished)
        store.addIfMissing(searchCandidate, trackingStatus: .watching)

        store.update(with: details(for: searchCandidate, totalEpisodeCount: 26), for: searchCandidate)

        #expect(store.items.first?.trackingStatus == .watching)
        #expect(store.items.first?.status == .airing)
    }

    @Test func preservesPosterURLWhenReloadingPersistedItems() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: LibraryItemModel.self,
            configurations: configuration
        )
        let store = FollowedMediaStore(
            repository: SwiftDataLibraryRepository(modelContext: container.mainContext)
        )
        let posterURL = try #require(URL(string: "https://image.tmdb.org/t/p/w342/poster.jpg"))
        store.toggle(candidate(id: 1, title: "Breaking Bad", posterURL: posterURL))

        store.reload()

        #expect(store.items.first?.posterURL == posterURL)
    }

    @Test func enrichesFollowedMediaWithLoadedDetails() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: LibraryItemModel.self,
            configurations: configuration
        )
        let store = FollowedMediaStore(
            repository: SwiftDataLibraryRepository(modelContext: container.mainContext)
        )
        let searchCandidate = candidate(id: 1, title: "Mushoku Tensei")
        store.toggle(searchCandidate)

        store.update(
            with: details(for: searchCandidate, totalEpisodeCount: 62),
            for: searchCandidate
        )

        #expect(store.items.first?.totalEpisodeCount == 62)
        #expect(store.items.first?.status == .airing)
    }
}

@MainActor
private final class MutableLibraryRepository: LibraryRepository {
    var items: [LibraryItem]
    var shouldFail = false

    init(items: [LibraryItem]) {
        self.items = items
    }

    func loadItems() throws -> [LibraryItem] {
        if shouldFail {
            throw TestError.failed
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

private enum TestError: Error { case failed }

private func candidate(
    id: Int,
    title: String,
    status: MediaStatus? = nil,
    posterURL: URL? = nil
) -> MediaCandidate {
    MediaCandidate(
        provider: .tmdb,
        providerID: id,
        kind: .tvShow,
        title: title,
        alternateTitle: nil,
        posterURL: posterURL,
        releaseYear: nil,
        totalEpisodeCount: nil,
        status: status,
        nextEpisodeNumber: nil,
        nextEpisodeAirDate: nil
    )
}

private func details(for candidate: MediaCandidate, totalEpisodeCount: Int) -> ShowDetails {
    ShowDetails(
        provider: candidate.provider,
        providerID: candidate.providerID,
        kind: candidate.kind,
        title: candidate.title,
        alternateTitle: candidate.alternateTitle,
        overview: nil,
        posterURL: candidate.posterURL,
        backdropURL: nil,
        releaseYear: candidate.releaseYear,
        status: .airing,
        totalEpisodeCount: totalEpisodeCount,
        genres: [],
        seasonSummaries: []
    )
}
