//
//  EpisodeScheduleStore.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation
import Observation

@MainActor @Observable
final class EpisodeScheduleStore: EpisodeScheduleReading {
    private let repository: any EpisodeScheduleRepository

    private(set) var schedules = [String: EpisodeSchedule]()
    private(set) var errorMessage: String?

    init(repository: any EpisodeScheduleRepository) {
        self.repository = repository
        reload()
    }

    func reload() {
        do {
            schedules = try Dictionary(
                uniqueKeysWithValues: repository.loadSchedules().map { ($0.id, $0) }
            )
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func schedule(for item: LibraryItem) -> EpisodeSchedule? {
        schedules[item.id]
    }

    func save(item: LibraryItem, seasons: [ShowSeason]) {
        let schedule = EpisodeSchedule(itemID: item.id, seasons: seasons)
        do {
            try repository.save(schedule)
            schedules[schedule.id] = schedule
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeSchedules(excluding itemIDs: Set<String>) {
        let staleScheduleIDs = schedules.keys.filter { !itemIDs.contains($0) }
        for id in staleScheduleIDs {
            do {
                try repository.delete(id: id)
                schedules.removeValue(forKey: id)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
