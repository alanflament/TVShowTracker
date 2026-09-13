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
            errorMessage = error.localizedDescription
        }
    }

    func contains(_ candidate: MediaCandidate) -> Bool {
        items.contains { $0.id == candidate.id }
    }

    func toggle(_ candidate: MediaCandidate) {
        toggle(candidate, trackingStatus: .watching)
    }

    func toggle(_ candidate: MediaCandidate, trackingStatus: TrackingStatus) {
        if contains(candidate) {
            remove(id: candidate.id)
        } else {
            addIfMissing(candidate, trackingStatus: trackingStatus)
        }
    }

    func addIfMissing(
        _ candidate: MediaCandidate,
        trackingStatus: TrackingStatus = .watching
    ) {
        guard !contains(candidate) else {
            return
        }
        save(LibraryItem(candidate: candidate, trackingStatus: trackingStatus))
    }

    func remove(_ item: LibraryItem) {
        remove(id: item.id)
    }

    func item(id: String) -> LibraryItem? {
        items.first { $0.id == id }
    }

    func updateStatus(_ status: MediaStatus, for item: LibraryItem) {
        guard let item = self.item(id: item.id), item.status != status else {
            return
        }
        save(item.updating(status: status))
    }

    func updateTrackingStatus(_ trackingStatus: TrackingStatus, for item: LibraryItem) {
        guard let item = self.item(id: item.id), item.trackingStatus != trackingStatus else {
            return
        }
        save(item.updating(trackingStatus: trackingStatus))
    }

    func update(with details: ShowDetails, for candidate: MediaCandidate) {
        guard let item = item(id: candidate.id) else {
            return
        }
        save(item.updating(with: details))
    }

    func recordLifecycleCheck(for item: LibraryItem, at date: Date = .now) {
        guard let item = self.item(id: item.id), item.lastLifecycleCheckAt != date else {
            return
        }
        save(item.updating(lastLifecycleCheckAt: date))
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
